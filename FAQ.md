# Gabay System FAQ

This document answers frequently asked questions about the system's backend processes.

***

### Q: What happens when an administrator moves a student to a new section?

When a student is moved from one section to another using the administrative tools, a comprehensive, automated process is triggered to ensure all related data is updated correctly and instantly. This process is atomic, meaning all steps must be completed successfully, or the entire operation is cancelled to prevent data inconsistencies.

Here is a step-by-step breakdown of the flow:

1.  **De-enrollment from Old Section:**
    *   The student is first de-registered from all subjects associated with their original section.
    *   The student count on the schedule for each of those subjects is automatically decreased by one.
    *   The total student count for the original section is also decreased by one.

2.  **Enrollment in New Section:**
    *   The student's primary record is updated, linking them to the new section and its corresponding grade level.
    *   The system automatically enrolls the student in all subjects required for the new section, taking into account specific curriculum requirements like SHS strands and semesters.
    *   The student count on the schedule for each new subject is increased by one.
    *   The total student count for the new section is increased by one.

3.  **Data Synchronization:**
    *   Finally, the system clears all relevant data caches related to the student, their old section, their new section, and general enrollment data. This ensures that the changes are reflected immediately across the entire platform, including in the student portal, teacher views, and all administrative dashboards.

***

### Q: What happens when an administrator dissolves a subject schedule?

Dissolving a single subject schedule (e.g., cancelling a specific Math class for Section A) is a sensitive operation that the system handles carefully to ensure no student is left without a class.

Here is the step-by-step process:

1.  **Initiation:** The administrator selects a specific schedule to dissolve.

2.  **Student Check:** The system first checks if there are any students currently enrolled in that schedule.
    *   **If no students are enrolled:** The administrator can simply provide a reason and dissolve the schedule. Its status is marked as `DISSOLVED`, and it is removed from view.
    *   **If students are enrolled:** The system prevents immediate dissolution. The administrator is presented with a list of all enrolled students and a list of valid alternative schedules for the same subject. They **must** select a new schedule for the students to be transferred to. Once confirmed, the system transfers the students and then dissolves the original schedule.
    *   **Data Integrity:** The entire process is handled in a single transaction, ensuring that student enrollment counts are correctly updated on both the old and new schedules, and all relevant data caches are cleared.

3.  **Mandatory Student Transfer:**
    *   The administrator is required to select a valid, alternative schedule for the same subject to which the enrolled students will be transferred. The system provides a list of available options and their current capacity.
    *   An administrator cannot proceed without selecting a valid transfer target.

4.  **Execution (Atomic Transaction):** Once a new schedule is chosen and the action is confirmed, the system performs the following steps in a single, all-or-nothing transaction:
    *   The `enrolled` count of the old, dissolved schedule is decreased.
    *   The `enrolled` count of the new, target schedule is increased.
    *   All relevant `SubjectEnrollment` records are updated, officially moving the students to the new schedule.
    *   The original schedule's status is permanently changed to `DISSOLVED`.

5.  **Notification & Cache Update:**
    *   Notifications are automatically sent to the affected students, informing them of the change to their schedule.
    *   All relevant system caches for schedules, faculty loads, and student records are cleared to ensure the changes are reflected everywhere instantly.

***

### Q: What happens when an administrator dissolves an entire section?

Dissolving an entire section is a significant administrative action that triggers a comprehensive, multi-step process to ensure data integrity and that every student is properly reassigned. The entire operation is atomic, meaning all steps must complete successfully, or the entire process is cancelled.

Here is the step-by-step breakdown of the flow:

1.  **Initiation and Validation:** The administrator selects a section to dissolve and provides a reason.
    *   **If the section has no students:** It can be safely marked as "Inactive" immediately.
    *   **If the section has students:** The administrator is presented with a list of all enrolled students. They **must** assign a new, valid section for each student from a list of available sections in the same grade level. The system validates that all students are mapped and that the target sections have enough capacity.

2.  **Transactional Student Transfers:** Once confirmed, the system performs the following actions for **each student** being transferred:
    *   The student is de-enrolled from all subjects associated with the old section.
    *   Their primary enrollment record is updated to link to the new section.
    *   The student's main record is updated with their new section assignment.
    *   The student is automatically enrolled in all the appropriate subjects for their new section.

3.  **Section Record Updates:**
    *   The student count of the dissolved section is updated to zero.
    *   The student counts for all receiving sections are correctly incremented.
    *   The dissolved section is marked as **Inactive**, effectively removing it from active use.

4.  **Data Synchronization:**
    *   Finally, the system clears all relevant data caches for the involved students, the dissolved section, and all the new sections. This ensures that the changes are reflected immediately and correctly across the entire platform for all users.

***

### Q: What is the "Sync Subjects" feature for and when should it be used?

The "Sync Subjects" feature is a powerful tool designed to ensure that all students within a section are correctly enrolled in all the subjects required by their curriculum. It should be used in specific situations where a section's subject list has been updated *after* students have already been enrolled.

Here is a breakdown of how it works and when to use it:

1.  **When to Use "Sync Subjects":**
    *   **Late Subject Addition:** The most common use case is when a new subject is added to a grade level's curriculum after the school year has started and students are already assigned to sections.
    *   **Data Discrepancy:** If there is a suspicion that some students in a section are missing enrollments for one or more subjects, running this sync can quickly resolve the discrepancy.

2.  **How It Works (Step-by-Step):**
    *   **Initiation:** The administrator selects a section and triggers the "Sync Subjects" action.
    *   **Student-by-Student Scan:** The system iterates through every student currently enrolled in that section.
    *   **Comparison:** For each student, it compares their list of current `SubjectEnrollment` records against the official list of subjects required for that section (taking into account the school year, semester, and SHS strand).
    *   **Enrollment Creation:** If a student is missing an enrollment for any required subject, the system automatically creates it. It intelligently tries to link this new enrollment to an existing schedule for that subject within the section. If no schedule exists, a placeholder is created.
    *   **Completion Report:** Once the process is complete, the system provides a report detailing how many new enrollments were created and for which subjects. If all students were already up-to-date, it confirms that no changes were needed.
    
3.  **Data Integrity:** The entire process is handled carefully to avoid creating duplicate enrollments. It only adds what is missing, ensuring every student's record is aligned with the official curriculum.
