class P2PTask {final String id;final String payload;final String? peerId;const P2PTask(this.id,this.payload,{this.peerId});}
class TaskDistributor {
  final List<P2PTask> pending=[];
  void enqueue(P2PTask task)=>pending.add(task);
  P2PTask? next(String peerId){for(final task in pending){if(task.peerId==null||task.peerId==peerId){pending.remove(task);return task;}}return null;}
}
