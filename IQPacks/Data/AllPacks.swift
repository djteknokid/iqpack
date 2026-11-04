import Foundation

// Packs are loaded from JSON files in Data/Packs/*.json
// To add a new pack: drop a new .json file in that folder and add it to the Xcode target.
let allPacks: [Pack] = PackLoader.loadAll()
