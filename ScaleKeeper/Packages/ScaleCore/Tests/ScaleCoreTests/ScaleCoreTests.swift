import XCTest
@testable import ScaleCore

final class ScaleCoreTests: XCTestCase {
    func testAnimalCreation() throws {
        let animal = Animal(
            name: "Test Snake",
            speciesID: UUID(),
            sex: .male
        )

        XCTAssertEqual(animal.name, "Test Snake")
        XCTAssertEqual(animal.sex, .male)
        XCTAssertEqual(animal.status, .active)
    }

    func testFeedingEventCreation() throws {
        let feeding = FeedingEvent(
            preyType: .mouse,
            preySize: .medium,
            preyState: .frozenThawed,
            quantity: 1,
            feedingResponse: .struckImmediately
        )

        XCTAssertEqual(feeding.preyType, .mouse)
        XCTAssertTrue(feeding.feedingResponse.isSuccessful)
    }

    func testWeightConversion() throws {
        let weight = WeightRecord(weightGrams: 500)

        XCTAssertEqual(weight.weightGrams, 500)
        XCTAssertEqual(weight.formattedWeight, "500 g")
    }
}
