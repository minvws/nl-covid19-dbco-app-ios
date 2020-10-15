/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum TaskStatus: Equatable {
    case notStarted
    case inProgress(Float)
    case completed
}

protocol OldTask {
    var identifier: String { get }
    var status: TaskStatus { get }
    var isSynced: Bool { get }
}

struct ContactDetailsTask: OldTask {
    let name: String
    var contact: Contact?
    var preferredStaffContact: Bool
    
    let identifier: String
    var status: TaskStatus
    var isSynced: Bool
}

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
    
    private(set) var tasks: [OldTask] = [
        ContactDetailsTask(name: "Aziz F", preferredStaffContact: false, identifier: UUID().uuidString, status: .notStarted, isSynced: false),
        ContactDetailsTask(name: "Job J", preferredStaffContact: false, identifier: UUID().uuidString, status: .completed, isSynced: false),
        ContactDetailsTask(name: "Lia B", preferredStaffContact: false, identifier: UUID().uuidString, status: .inProgress(0.3), isSynced: false),
        ContactDetailsTask(name: "Thom H", preferredStaffContact: true, identifier: UUID().uuidString, status: .inProgress(0.8), isSynced: false)
    ]
    
    var hasUnfinishedTasks: Bool {
        tasks.contains { $0.status != .completed }
    }
    
    func setContact(_ contact: Contact, for task: ContactDetailsTask) {
        guard let index = tasks.lastIndex(where: { $0.identifier == task.identifier }) else {
            return
        }
        
        var updatedTask = task
        updatedTask.contact = contact
        updatedTask.isSynced = false
        updatedTask.status = .completed
        
        tasks[index] = updatedTask
        
        listeners.forEach { $0.listener?.taskManagerDidUpdateTasks(self) }
        isSynced = false
    }
    
    func addContact(_ contact: Contact) {
        tasks.append(ContactDetailsTask(name: contact.fullName,
                                        contact: contact,
                                        preferredStaffContact: false,
                                        identifier: UUID().uuidString,
                                        status: .completed,
                                        isSynced: false))
        
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
