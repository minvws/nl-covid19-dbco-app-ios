/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol Task {
    var identifier: String { get }
    var completed: Bool { get }
    var isSynced: Bool { get }
}

struct ContactDetailsTask: Task {
    let name: String
    var contact: Contact?
    
    let identifier: String
    var completed: Bool
    var isSynced: Bool
}

protocol TaskManagerListener: class {
    func taskManagerDidUpdateTasks(_ taskManager: TaskManager)
}

final class TaskManager {
    
    private var listeners = [TaskManagerListener?]()
    
    private(set) var tasks: [Task] = [
        ContactDetailsTask(name: "Aziz F", identifier: UUID().uuidString, completed: false, isSynced: false),
        ContactDetailsTask(name: "Job J", identifier: UUID().uuidString, completed: false, isSynced: false),
        ContactDetailsTask(name: "J Attema", identifier: UUID().uuidString, completed: false, isSynced: false),
        ContactDetailsTask(name: "Thom H", identifier: UUID().uuidString, completed: false, isSynced: false)
    ]
    
    func setContact(_ contact: Contact, for task: ContactDetailsTask) {
        guard let index = tasks.lastIndex(where: { $0.identifier == task.identifier }) else {
            return
        }
        
        var updatedTask = task
        updatedTask.contact = contact
        updatedTask.isSynced = false
        updatedTask.completed = contact.isValid
        
        tasks[index] = updatedTask
        
        listeners.forEach { $0?.taskManagerDidUpdateTasks(self) }
    }
    
    func addContact(_ contact: Contact) {
        tasks.append(ContactDetailsTask(name: contact.fullName,
                                        contact: contact,
                                        identifier: UUID().uuidString,
                                        completed: contact.isValid,
                                        isSynced: false))
        
        listeners.forEach { $0?.taskManagerDidUpdateTasks(self) }
    }
    
    func addListener(_ listener: TaskManagerListener) {
        weak var weakListener = listener
        listeners.append(weakListener)
    }
    
}
