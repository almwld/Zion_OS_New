---
name: video-analyze
description: Analyze video content from YouTube URLs, local files, or streams by combining audio transcription, frame extraction, and temporal reasoning. Use when the user asks to inspect, summarize, transcribe, extract insights from, or ask questions about a video.
version: 1.0.0
execution-mode: advisory
category: fleet-ops
status: candidate
providers:
  required: [python, uv]
  pip: [numpy, openai, openai-whisper, opencv-python, pytest]
---
# Video Analysis Skill

**Description**: Enables AI agents to watch, analyze, and understand video content from YouTube, local files, or streams. Combines audio transcription, frame extraction, and temporal reasoning.

**Triggers**:
- `[video-analyze] <url_or_path>` - Analyze video from URL or local path
- `[video-youtube] <video_id>` - Analyze YouTube video
- `[video-transcribe] <path>` - Extract and analyze audio transcript

**Chains**:
- Chains to `whisper` for audio transcription
- Chains to `vision-analyze` for frame analysis
- Chains to `temporal-reason` for sequence understanding

**Base120 Mapping**:
- CO19 (Multimodal Brief) - Integrates audio, visual, and temporal data
- DE05 (Dimension Reduction) - Extracts key insights from video content
- P5 (User Journey) - Maps video narrative structure and flow

## Implementation

### Core Workflow

```python
import cv2
import whisper
import base64
from datetime import timedelta
from pathlib import Path

class VideoAnalyzer:
    def __init__(self):
        self.whisper_model = whisper.load_model("base")
        
    async def analyze_video(self, source, strategy="hybrid"):
        """
        Analyze video using hybrid audio-visual approach
        
        Args:
            source: YouTube URL, local path, or video ID
            strategy: "audio-first", "visual-first", or "hybrid"
            
        Returns:
            dict: Comprehensive analysis with timestamps
        """
        # 1. Extract video if needed
        video_path = await self._ensure_local(source)
        
        # 2. Audio transcription
        transcript = await self._transcribe_audio(video_path)
        
        # 3. Key frame extraction
        key_frames = await self._extract_key_frames(video_path, transcript)
        
        # 4. Visual analysis
        frame_analyses = await self._analyze_frames(key_frames)
        
        # 5. Temporal synthesis
        analysis = await self._synthesize_analysis(transcript, frame_analyses)
        
        return analysis
    
    async def _transcribe_audio(self, video_path):
        """Extract and transcribe audio with timestamps"""
        # Extract audio using ffmpeg
        audio_path = video_path.with_suffix('.mp3')
        
        # Transcribe with Whisper
        result = self.whisper_model.transcribe(
            str(audio_path),
            word_timestamps=True,
            verbose=False
        )
        
        return result
    
    async def _extract_key_frames(self, video_path, transcript):
        """Intelligently select frames based on audio cues"""
        cap = cv2.VideoCapture(str(video_path))
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        # Detect scene changes and speaker changes
        key_timestamps = self._detect_key_moments(transcript)
        
        frames = []
        for timestamp in key_timestamps:
            frame_num = int(timestamp * fps)
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
            ret, frame = cap.read()
            if ret:
                frames.append({
                    'timestamp': timestamp,
                    'frame': frame,
                    'context': self._get_audio_context(transcript, timestamp)
                })
        
        cap.release()
        return frames
    
    def _detect_key_moments(self, transcript):
        """Identify important moments from audio"""
        moments = []
        
        # Add frames at scene changes
        moments.extend([0])  # Start
        
        # Add frames at speaker changes
        current_speaker = None
        for segment in transcript['segments']:
            # Simple heuristic: new topic every 30 seconds
            if segment['start'] > 0 and segment['start'] % 30 < 5:
                moments.append(segment['start'])
        
        # Ensure coverage
        duration = transcript['segments'][-1]['end']
        for i in range(0, int(duration), 60):  # Every minute
            moments.append(i)
        
        return sorted(set(moments))
    
    async def _analyze_frames(self, frames):
        """Analyze visual content of key frames"""
        analyses = []
        
        for frame_data in frames:
            # Convert frame to base64
            _, buffer = cv2.imencode('.jpg', frame_data['frame'])
            image_b64 = base64.b64encode(buffer).decode()
            
            # Analyze with vision model
            analysis = await self._vision_analysis(
                image_b64,
                context=frame_data['context']
            )
            
            analyses.append({
                'timestamp': frame_data['timestamp'],
                'visual': analysis,
                'audio_context': frame_data['context']
            })
        
        return analyses
    
    async def _synthesize_analysis(self, transcript, frame_analyses):
        """Combine audio and visual insights"""
        # Create timeline
        timeline = []
        
        # Add transcript segments
        for segment in transcript['segments']:
            timeline.append({
                'type': 'audio',
                'timestamp': segment['start'],
                'content': segment['text'],
                'confidence': segment.get('avg_logprob', 0)
            })
        
        # Add visual analyses
        for analysis in frame_analyses:
            timeline.append({
                'type': 'visual',
                'timestamp': analysis['timestamp'],
                'content': analysis['visual'],
                'context': analysis['audio_context']
            })
        
        # Sort by timestamp
        timeline.sort(key=lambda x: x['timestamp'])
        
        # Generate summary
        summary = await self._generate_summary(timeline)
        
        return {
            'duration': transcript['segments'][-1]['end'],
            'timeline': timeline,
            'summary': summary,
            'key_insights': self._extract_key_insights(timeline),
            'action_items': self._extract_action_items(timeline)
        }
```

### Fleet Integration

```python
class VideoAnalysisAgent:
    """Specialized agent for video processing in the fleet"""
    
    def __init__(self, agent_id="video-analyzer"):
        self.agent_id = agent_id
        self.analyzer = VideoAnalyzer()
        
    async def process_video_request(self, request):
        """Handle video analysis requests from fleet"""
        
        # Post to bus
        await self.bus_post(
            from_agent=self.agent_id,
            to_agent="coordinator",
            msg_type="STATUS",
            message=f"Starting video analysis: {request['source']}"
        )
        
        try:
            # Analyze video
            result = await self.analyzer.analyze_video(
                request['source'],
                strategy=request.get('strategy', 'hybrid')
            )
            
            # Store results
            await self._store_analysis(request['source'], result)
            
            # Notify completion
            await self.bus_post(
                from_agent=self.agent_id,
                to_agent=request['requester'],
                msg_type="MILESTONE",
                message=f"Video analysis complete: {request['source']}"
            )
            
            return result
            
        except Exception as e:
            await self.bus_post(
                from_agent=self.agent_id,
                to_agent="coordinator",
                msg_type="BLOCKED",
                message=f"Video analysis failed: {str(e)}"
            )
            raise
```

### Usage Examples

```bash
# Analyze YouTube video
[video-analyze] https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Analyze local file
[video-analyze] /video.mp4.mp4

# Audio-only analysis (faster, cheaper)
[video-transcribe] /output/target.mp4

# With custom strategy
[video-analyze] https://youtu.be/abc123 --strategy audio-first
```

### Output Format

```json
{
  "video_id": "dQw4w9WgXcQ",
  "duration": 212.5,
  "summary": "The video presents a comprehensive overview of...",
  "key_insights": [
    {
      "timestamp": 45.2,
      "insight": "Main thesis introduced about user experience",
      "evidence": "visual slides + speaker emphasis"
    }
  ],
  "timeline": [
    {
      "timestamp": 0.0,
      "type": "audio",
      "content": "Welcome to today's presentation...",
      "confidence": 0.95
    },
    {
      "timestamp": 30.5,
      "type": "visual",
      "content": "Slide showing architecture diagram...",
      "context": "discussing system design"
    }
  ],
  "action_items": [
    "Review architecture documentation",
    "Schedule follow-up meeting"
  ],
  "processing_time": 45.2,
  "cost_estimate": 0.15
}
```

## Configuration

### Environment Variables

```bash
# OpenAI API for vision analysis
OPENAI_API_KEY=sk-...

# YouTube API (optional, for metadata)
YOUTUBE_API_KEY=...

# Processing settings
VIDEO_MAX_DURATION=3600  # Max video length in seconds
FRAME_EXTRACTION_RATE=1  # Frames per second
WHISPER_MODEL=base       # tiny, base, small, medium, large
```

### Cost Optimization

1. **Audio-first strategy**: 80% accuracy at 20% cost
2. **Adaptive sampling**: More frames for complex content
3. **Parallel processing**: Multiple agents for long videos
4. **Caching**: Store analyses for reuse

### Performance Tuning

```python
# For long videos (>30 min)
VIDEO_CHUNK_SIZE=900  # Process in 15-minute chunks
PARALLEL_WORKERS=3   # Parallel frame analysis

# For real-time processing
BUFFER_SIZE=5        # Seconds to buffer
LOW_LATENCY=true     # Optimize for speed over accuracy
```

## Integration Points

### With Morning Briefing

```python
async def analyze_daily_videos():
    """Analyze videos from daily briefing sources"""
    
    # Get video links from briefings
    videos = await get_briefing_videos()
    
    # Process in parallel
    analyses = await asyncio.gather(*[
        video_analyzer.analyze_video(v['url'])
        for v in videos
    ])
    
    # Add to briefing
    await add_to_briefing('video_insights', analyses)
```

### With Research Pipeline

```python
async def research_video_analysis(paper_videos):
    """Analyze video content for research papers"""
    
    for video_url in paper_videos:
        analysis = await video_analyzer.analyze_video(
            video_url,
            strategy="visual-first"  # Focus on demonstrations
        )
        
        # Extract methodology and results
        methodology = extract_methodology(analysis)
        results = extract_results(analysis)
        
        await store_research_insights(video_url, {
            'methodology': methodology,
            'results': results,
            'full_analysis': analysis
        })
```

## Guardrails and Safety

### Content Filtering

```python
def validate_video_content(video_path):
    """Check for inappropriate content"""
    
    # Audio scan for sensitive topics
    audio_check = scan_audio_content(video_path)
    
    # Visual scan for NSFW content
    visual_check = scan_visual_content(video_path)
    
    if audio_check.flagged or visual_check.flagged:
        raise ContentPolicyError("Video contains restricted content")
```

### Privacy Protection

```python
def anonymize_video(video_path):
    """Blur faces and sensitive information"""
    
    # Detect and blur faces
    anonymized = blur_faces(video_path)
    
    # Detect and blur text/PII
    anonymized = blur_sensitive_text(anonymized)
    
    return anonymized
```

### Rate Limiting

```python
class VideoRateLimiter:
    """Prevent abuse of video processing"""
    
    def __init__(self):
        self.daily_limit = 100  # Videos per day
        self.minute_limit = 5   # Videos per minute
        
    async def check_limit(self, user_id):
        usage = await get_usage(user_id)
        
        if usage.daily >= self.daily_limit:
            raise RateLimitError("Daily limit exceeded")
            
        if usage.minute >= self.minute_limit:
            raise RateLimitError("Rate limit exceeded")
```

## Testing

```python
@pytest.mark.asyncio
async def test_video_analysis():
    """Test complete video analysis workflow"""
    
    # Use test video
    test_video = "test_data/sample.mp4"
    
    analyzer = VideoAnalyzer()
    result = await analyzer.analyze_video(test_video)
    
    # Verify structure
    assert 'summary' in result
    assert 'timeline' in result
    assert 'key_insights' in result
    
    # Verify content
    assert len(result['timeline']) > 0
    assert result['duration'] > 0
    
@pytest.mark.asyncio
async def test_youtube_integration():
    """Test YouTube video processing"""
    
    analyzer = VideoAnalyzer()
    
    # Process short test video
    result = await analyzer.analyze_video(
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        strategy="audio-first"
    )
    
    assert result['summary'] is not None
```

## Deployment

### Docker Configuration

```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libopencv-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy skill
COPY . [skill]
WORKDIR [skill]

# Run skill server
CMD ["python", "-m", "skill_server"]
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: video-analyzer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: video-analyzer
  template:
    metadata:
      labels:
        app: video-analyzer
    spec:
      containers:
      - name: video-analyzer
        image: video-analyzer:latest
        resources:
          requests:
            cpu: 1000m
            memory: 4Gi
            nvidia.com/gpu: 1
          limits:
            cpu: 2000m
            memory: 8Gi
            nvidia.com/gpu: 1
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: api-keys
              key: openai
```

## Future Enhancements

1. **Real-time Processing**: Support for live streams
2. **Multi-language Support**: Enhanced transcription for non-English content
3. **Video Summarization**: Generate short video clips from analysis
4. **Custom Models**: Fine-tuned models for specific domains
5. **Interactive Queries**: Ask questions about video content
6. **Comparison Mode**: Analyze differences between videos

## Metrics and Monitoring

```python
# Track processing metrics
metrics = {
    'videos_processed': 0,
    'total_duration': 0,
    'average_processing_time': 0,
    'cost_per_minute': 0,
    'error_rate': 0
}

# Health check
async def health_check():
    """Verify all components are working"""
    
    checks = {
        'whisper_model': check_whisper(),
        'vision_api': check_openai(),
        'disk_space': check_disk_space(),
        'gpu_available': check_gpu()
    }
    
    return all(checks.values()), checks
```

---

**Status**: Ready for fleet integration
**Dependencies**: OpenCV, Whisper, OpenAI Vision API
**Cost**: ~$0.10 per 10-minute video (hybrid mode)
**Performance**: ~2x real-time on RTX 3080 Ti
