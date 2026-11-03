class FuzzyMatcher {
  const FuzzyMatcher();
  static int levenshtein(String a,String b){
    if(a==b)return 0;
    if(a.isEmpty)return b.runes.length;
    if(b.isEmpty)return a.runes.length;
    final left=a.toLowerCase().runes.toList(),right=b.toLowerCase().runes.toList();
    var previous=List<int>.generate(right.length+1,(i)=>i);
    for(var i=1;i<=left.length;i++){
      final current=List<int>.filled(right.length+1,0)..[0]=i;
      for(var j=1;j<=right.length;j++){
        final cost=left[i-1]==right[j-1]?0:1;
        current[j]=[
          current[j-1]+1,
          previous[j]+1,
          previous[j-1]+cost
        ].reduce((x,y)=>x<y?x:y);
      }
      previous=current;
    }
    return previous.last;
  }
  static List<String> suggest(String input,List<String> candidates,{int maxDistance=2})=>
    candidates.map((c)=>(value:c,distance:levenshtein(input,c)))
      .where((e)=>e.distance<=maxDistance).toList()
      ..sort((a,b)=>a.distance.compareTo(b.distance));
}
