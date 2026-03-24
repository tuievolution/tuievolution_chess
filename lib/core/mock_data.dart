class MockData {
  // Tuana backend'i bağlayana kadar arayüzü test etmek için oluşturduğumuz sahte veriler
  static const Map<String, dynamic> testOpening = {
    "name": "Ruy Lopez (Test)",
    "fen": "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3",
    "variants": [
      {"id": 1, "name": "Morphy Defense", "moves": "a6", "isCompleted": true}, // Yeşil yaprak alacak
      {"id": 2, "name": "Berlin Defense", "moves": "Nf6", "isCompleted": false},
      {"id": 3, "name": "Schliemann Defense", "moves": "f5", "isCompleted": false},
      {"id": 4, "name": "Steinitz Defense", "moves": "d6", "isCompleted": false},
      {"id": 5, "name": "Bird's Defense", "moves": "Nd4", "isCompleted": false},
      {"id": 6, "name": "Classical Defense", "moves": "Bc5", "isCompleted": false},
      {"id": 7, "name": "Cozio Defense", "moves": "Nge7", "isCompleted": true}, // Yeşil yaprak alacak
      {"id": 8, "name": "Smyslov Defense", "moves": "g6", "isCompleted": false},
    ]
  };
}