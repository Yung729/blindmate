class GameValidator2 {
  static bool isValidMove(List<String> board, int index) {
    return index >= 0 && index < 9 && board[index].isEmpty;
  }
} 