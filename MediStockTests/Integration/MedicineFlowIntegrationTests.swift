import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineFlowIntegrationTests {
    private func makeSUT(medicines: [Medicine] = [], isConnected: Bool = true) -> IntegrationTestApp {
        IntegrationTestApp(medicines: medicines, isConnected: isConnected)
    }

    private func addMedicine(
        _ name: String,
        stock: Int,
        aisle: String,
        to app: IntegrationTestApp
    ) async -> Bool {
        let add = app.container.viewModelFactory.makeAddMedicineViewModel()
        add.name = name
        add.stock = stock
        add.aisle = aisle
        return await add.save()
    }

    // MARK: - Création → liste → historique

    @Test func creatingAMedicineFillsTheListAndItsHistory() async throws {
        let app = makeSUT()
        let list = app.container.viewModelFactory.makeMedicineListViewModel()

        await list.loadIfNeeded()
        #expect(list.filteredAndSortedMedicines.isEmpty)
        #expect(app.fakeMedicines.fetchCallCount == 1)

        let fetchesBeforeSave = app.fakeMedicines.fetchCallCount
        let didSave = await addMedicine("Doliprane", stock: 12, aisle: "Rayon 1", to: app)

        #expect(didSave)
        #expect(app.fakeMedicines.fetchCallCount == fetchesBeforeSave + 1)
        #expect(list.errorMessage == nil)
        #expect(list.filteredAndSortedMedicines.count == 1)
        let created = try #require(list.filteredAndSortedMedicines.first(where: { $0.name == "Doliprane" }))
        #expect(created.stock == 12)
        #expect(created.aisle == "Rayon 1")
        #expect(app.container.medicineStore.medicines.count == 1)

        let detail = app.container.viewModelFactory.makeMedicineDetailViewModel(medicineId: created.id)
        #expect(detail.medicine?.name == "Doliprane")

        let historyFetchesSoFar = app.fakeHistory.fetchCallCount
        await detail.loadHistory()

        #expect(app.fakeHistory.fetchCallCount == historyFetchesSoFar + 1)
        #expect(detail.history.count == 1)
        let entry = try #require(detail.history.first(where: { $0.action == "Ajout de Doliprane" }))
        #expect(entry.details == "Créé avec un stock de 12 dans Rayon 1")
        #expect(entry.medicineId == created.id)
    }

    // MARK: - Mouvement de stock → propagation → historique

    @Test func aStockChangeReachesTheThreeScreensWithoutARead() async throws {
        let app = makeSUT()
        let list = app.container.viewModelFactory.makeMedicineListViewModel()
        await list.loadIfNeeded()

        let didSave = await addMedicine("Doliprane", stock: 12, aisle: "Rayon 1", to: app)
        #expect(didSave)
        let created = try #require(list.filteredAndSortedMedicines.first(where: { $0.name == "Doliprane" }))

        let detail = app.container.viewModelFactory.makeMedicineDetailViewModel(medicineId: created.id)
        let aisleMedicines = app.container.viewModelFactory.makeAisleMedicinesViewModel(aisle: "Rayon 1")
        #expect(aisleMedicines.medicines.count == 1)

        let medicineFetchesSoFar = app.fakeMedicines.fetchCallCount
        let historyFetchesSoFar = app.fakeHistory.fetchCallCount

        await detail.increaseStock()

        #expect(app.fakeMedicines.fetchCallCount == medicineFetchesSoFar)
        #expect(app.fakeHistory.fetchCallCount == historyFetchesSoFar + 1)
        #expect(detail.errorMessage == nil)
        #expect(detail.medicine?.stock == 13)
        #expect(app.container.medicineStore.medicines.first(where: { $0.id == created.id })?.stock == 13)
        #expect(list.filteredAndSortedMedicines.first(where: { $0.id == created.id })?.stock == 13)
        #expect(aisleMedicines.medicines.first(where: { $0.id == created.id })?.stock == 13)
        #expect(detail.history.count == 2)
        #expect(detail.history.map(\.action).contains("Ajout de Doliprane"))
        #expect(detail.history.map(\.action).contains("Stock de Doliprane augmenté de 1"))
    }

    // MARK: - Suppression → liste, rayons et écran de rayon

    @Test func deletingFromTheListRemovesTheMedicineAndItsAisle() async throws {
        let app = makeSUT()
        let list = app.container.viewModelFactory.makeMedicineListViewModel()
        list.sortOption = .name
        await list.loadIfNeeded()

        #expect(await addMedicine("Doliprane", stock: 12, aisle: "Rayon 1", to: app))
        #expect(await addMedicine("Ibuprofène", stock: 5, aisle: "Rayon 2", to: app))

        let aisleList = app.container.viewModelFactory.makeAisleListViewModel()
        let aisleMedicines = app.container.viewModelFactory.makeAisleMedicinesViewModel(aisle: "Rayon 1")
        #expect(aisleList.aisles == ["Rayon 1", "Rayon 2"])
        #expect(aisleMedicines.medicines.count == 1)

        let target = try #require(list.filteredAndSortedMedicines.first(where: { $0.name == "Doliprane" }))
        let row = try #require(list.filteredAndSortedMedicines.firstIndex(where: { $0.id == target.id }))
        let fetchesSoFar = app.fakeMedicines.fetchCallCount

        await list.delete(atOffsets: IndexSet(integer: row))

        #expect(list.errorMessage == nil)
        #expect(app.fakeMedicines.deletedIds == [target.id])
        #expect(app.fakeMedicines.fetchCallCount == fetchesSoFar + 1)
        #expect(!list.filteredAndSortedMedicines.contains(where: { $0.id == target.id }))
        #expect(list.filteredAndSortedMedicines.count == 1)
        #expect(aisleList.aisles == ["Rayon 2"])
        #expect(aisleMedicines.medicines.isEmpty)
        #expect(app.container.medicineStore.medicines.count == 1)
    }
}
