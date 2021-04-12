import XCTest
import Unrealm
import SnapshotTesting
import RealmSwift
import Realm


struct Thing: Realmable, Equatable {

    var id: String = "id"
    var integer: Int = 1
    var double: Double = 2.5
    var optionalString: String? = nil
    var optionalInt: Int? = nil
    var optionalDouble: Double? = nil
    var date: Date = .init(timeIntervalSince1970: 0)
    var optionalDate: Date? = nil

    static func primaryKey() -> String? {
        "id"
    }

    init() {}

    init(
        id: String = "id",
        integer: Int = 1,
        double: Double = 2.5,
        optionalString: String? = nil,
        optionalInt: Int? = nil,
        optionalDouble: Double? = nil,
        date: Date = .init(timeIntervalSince1970: 0),
        optionalDate: Date? = nil
    ) {
        self.id = id
        self.integer = integer
        self.double = double
        self.optionalString = optionalString
        self.optionalInt = optionalInt
        self.optionalDouble = optionalDouble
        self.date = date
        self.optionalDate = optionalDate
    }
}


struct Parent: Realmable {
    var id: String = ""
    var thing: Thing?
    var otherThings: [Thing] = []


    static func primaryKey() -> String? {
        "id"
    }

    init() {}

    init(
        id: String,
        thing: Thing,
        otherThings: [Thing]
    ) {
        self.id = id
        self.thing = thing
        self.otherThings = otherThings
    }
}


final class UnrealmTests: XCTestCase {

    lazy var realm: Realm = {
        let realmableTypes: [RealmableBase.Type] = [Thing.self]
        return try! Realm(
            configuration: Realm.Configuration.init(
                inMemoryIdentifier: self.name,
                objectTypes: [
                    Thing.objectType()!,
                    Parent.objectType()!
                ]))
    }()

    override func setUp() {
        super.setUp()
        Realm.registerRealmables([Thing.self, Parent.self])
//        isRecording = true
    }


    // MARK: Write Tests

    func test_save() {
        try! realm.write {
            realm.add(Thing(), update: .all)
        }

        let objects = realm.dynamicObjects("RLMThing")
        assertSnapshot(matching: Array(objects), as: .dump)
    }


    func test_schema() {
        assertSnapshot(matching: realm.schema, as: .dump)
    }


    func test_save_multiple() {
        try! realm.write {
            realm.add(
                [Thing(id: "1"),
                 Thing(
                    id: "2",
                    optionalString: "Hello",
                    optionalInt: 3,
                    optionalDouble: 4.5,
                    optionalDate: Date(timeIntervalSince1970: 100)),
                 Thing(id: "3")],
                update: true)
        }

        let objects = realm.dynamicObjects("RLMThing")
        assertSnapshot(matching: Array(objects), as: .dump)
    }


    func test_update() {
        try! realm.write {
            realm.add(Thing(), update: .all)
        }

        var thing = realm.object(ofType: Thing.self, forPrimaryKey: "id")!

        thing.optionalString = "Updated"
        try! realm.write {
            realm.add(thing, update: .all)
        }
        let objects = realm.dynamicObjects("RLMThing")
        assertSnapshot(matching: Array(objects), as: .dump)
    }


    func test_update_value_to_nil() {
        try! realm.write {
            realm.add(Thing(optionalString: "original"), update: .all)
        }

        var thing = realm.object(ofType: Thing.self, forPrimaryKey: "id")!
        XCTAssertEqual(thing.optionalString, "original")

        thing.optionalString = nil
        try! realm.write {
            realm.add(thing, update: .all)
        }
        let objects = realm.dynamicObjects("RLMThing")
        assertSnapshot(matching: Array(objects), as: .dump)
    }


    func test_delete() {
        try! realm.write {
            realm.add(Thing(), update: .all)
        }

        let thing = realm.object(ofType: Thing.self, forPrimaryKey: "id")!

        try! realm.write {
            realm.delete(thing)
        }

        let objects = realm.dynamicObjects("RLMThing")
        XCTAssertTrue(objects.isEmpty)
    }


    func test_delete_multiple() {
        try! realm.write {
            realm.add(
                [Thing(id: "1"),
                 Thing(
                    id: "2",
                    optionalString: "Hello",
                    optionalInt: 3,
                    optionalDouble: 4.5,
                    optionalDate: Date(timeIntervalSince1970: 100)),
                 Thing(id: "3")],
                update: true)
        }

        let things = Array(realm.objects(Thing.self))
        
        XCTAssertTrue(!things.isEmpty)
        try! realm.write {
            realm.delete(things)
        }

        let objects = realm.dynamicObjects("RLMThing")
        XCTAssertTrue(objects.isEmpty)
    }


    // MARK: Fetch Tests

    func test_fetch_by_id_success() {
        try! realm.write {
            realm.add(Thing(id: "1"), update: .all)
        }

        let thing = realm.object(ofType: Thing.self, forPrimaryKey: "1")
        XCTAssertNotNil(thing)

        assertSnapshot(matching: thing, as: .dump)
    }


    func test_fetch_by_id_fail() {
        try! realm.write {
            realm.add(Thing(id: "1"), update: .all)
        }

        let thing = realm.object(ofType: Thing.self, forPrimaryKey: "2")
        XCTAssertNil(thing)
    }


    func test_fetch_multiple() {
        try! realm.write {
            realm.add(
                [Thing(id: "1"),
                 Thing(
                    id: "2",
                    optionalString: "Hello",
                    optionalInt: 3,
                    optionalDouble: 4.5,
                    optionalDate: Date(timeIntervalSince1970: 100)),
                 Thing(id: "3")],
                update: true)
        }

        let things = realm.objects(Thing.self)
        assertSnapshot(matching: Array(things), as: .dump)
    }


    func test_fetch_filter() {
        try! realm.write {
            realm.add(
                [Thing(id: "1"),
                 Thing(
                    id: "2",
                    optionalString: "Hello",
                    optionalInt: 3,
                    optionalDouble: 4.5,
                    optionalDate: Date(timeIntervalSince1970: 100)),
                 Thing(id: "3")],
                update: true)
        }

        let things = realm.objects(Thing.self).filter(NSPredicate(format: "optionalDate != nil"))
        assertSnapshot(matching: Array(things), as: .dump)
    }


    // MARK: Relationship Saves

    func test_relationship_save() {
        let parent = Parent(
            id: "parent",
            thing: Thing(),
            otherThings: [
                Thing(
                   id: "2",
                   optionalString: "Hello",
                   optionalInt: 3,
                   optionalDouble: 4.5,
                   optionalDate: Date(timeIntervalSince1970: 100)),
                Thing(id: "3")
            ])

        try! realm.write {
            realm.add(parent, update: .all)
        }

        let objects = realm.dynamicObjects("RLMParent")
        assertSnapshot(matching: Array(objects), as: .dump)
    }


    func test_relationship_modify_child() {
        var parent = Parent(
            id: "parent",
            thing: Thing(),
            otherThings: [
                Thing(
                   id: "2",
                   optionalString: "Hello",
                   optionalInt: 3,
                   optionalDouble: 4.5,
                   optionalDate: Date(timeIntervalSince1970: 100)),
                Thing(id: "3")
            ])

        try! realm.write {
            realm.add(parent, update: .all)
        }

        parent.thing?.optionalString = "updated"
        parent.otherThings[0].optionalString = "other updated"

        try! realm.write {
            realm.add(parent, update: .all)
        }

        let objects = realm.dynamicObjects("RLMParent")
        assertSnapshot(matching: Array(objects), as: .dump)
    }
}
