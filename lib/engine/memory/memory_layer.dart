enum MemoryLayer { conversation, user, project, task, skill, knowledge }
extension MemoryLayerX on MemoryLayer {
 String get label=>switch(this){MemoryLayer.conversation=>'محادثة',MemoryLayer.user=>'مستخدم',MemoryLayer.project=>'مشروع',MemoryLayer.task=>'مهام',MemoryLayer.skill=>'مهارات',MemoryLayer.knowledge=>'معرفة'};
}