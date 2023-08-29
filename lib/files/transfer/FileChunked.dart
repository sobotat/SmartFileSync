
class FileChunked {

  FileChunked({
    required this.fileName,
    required this.fileSize,
    required this.chunkCount,
  }) {
    for(int i = 0; i < chunkCount; i++) {
      chunkBytes.add([]);
    }
  }

  String fileName;
  int fileSize;

  int addedChunks = 0;
  int chunkCount;
  List<List<int>> chunkBytes = [];

  void addChunk({
    required int index,
    required List<int> chunk
  }) {
    chunkBytes[index] = chunk;
    addedChunks += 1;
  }

  List<int> checkForMissingChunks(){
    List<int> missing = [];

    for(int i = 0; i < chunkBytes.length; i++) {
      if(chunkBytes[i].isEmpty) {
        missing.add(i);
      }
    }

    return missing;
  }

  List<int> get fileBytes {
    List<int> out = [];

    for(List<int> chunk in chunkBytes) {
      out.addAll(chunk);
    }

    return out;
  }
}