/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol TaskManagerListener: class {
    func taskManagerDidUpdateTasks(_ taskManager: TaskManager)
    func taskManagerDidUpdateSyncState(_ taskManager: TaskManager)
}

// Temporary implementation
final class TaskManager {
    
    private struct ListenerWrapper {
        weak var listener: TaskManagerListener?
    }
    
    private var listeners = [ListenerWrapper]()
    
    private(set) var isSynced: Bool = false {
        didSet {
            listeners.forEach { $0.listener?.taskManagerDidUpdateSyncState(self) }
        }
    }
    
    private(set) var tasks = [Task]()
    
    var hasUnfinishedTasks: Bool {
        tasks.contains { $0.status != .completed }
    }
    
    func loadTasks(completion: @escaping () -> Void) {
        // Temporary implementation
        Services.network.getTasks(caseIdentifier: "1234") { result in
            self.tasks = (try? result.get()) ?? []
            self.listeners.forEach { $0.listener?.taskManagerDidUpdateTasks(self) }
            completion()
        }
    }
    
    func setContact(_ contact: OldContact, for task: Task) {
//        guard let index = tasks.lastIndex(where: { $0.uuid == task.uuid }) else {
//            return
//        }
//        
//        var updatedTask = task
//        updatedTask.contact = contact
//        updatedTask.isSynced = false
//        updatedTask.status = .completed
//
//        tasks[index] = updatedTask
        
        listeners.forEach { $0.listener?.taskManagerDidUpdateTasks(self) }
        isSynced = false
    }
    
    func addContact(_ contact: OldContact) {
//        tasks.append(ContactDetailsTask(name: contact.fullName,
//                                        contact: contact,
//                                        preferredStaffContact: false,
//                                        identifier: UUID().uuidString,
//                                        status: .completed,
//                                        isSynced: false))
        
        listeners.forEach { $0.listener?.taskManagerDidUpdateTasks(self) }
        isSynced = false
    }
    
    func addListener(_ listener: TaskManagerListener) {
        listeners.append(ListenerWrapper(listener: listener))
    }
    
    func sync(completionHandler: ((Bool) -> Void)?) {
        // Fake doing some work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isSynced = true
            completionHandler?(true)
        }
    }
    
}
