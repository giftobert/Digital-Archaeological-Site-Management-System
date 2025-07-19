;; Public Access Contract
;; Manages tourist visits and educational programs

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-VISIT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-CAPACITY-EXCEEDED (err u503))
(define-constant ERR-PROGRAM-NOT-FOUND (err u504))

;; Data Variables
(define-data-var next-visit-id uint u1)
(define-data-var next-program-id uint u1)
(define-data-var total-visits uint u0)
(define-data-var total-revenue uint u0)

;; Data Maps
(define-map site-access-rules
  { site-id: uint }
  {
    daily-capacity: uint,
    entry-fee: uint,
    access-restrictions: (string-ascii 50),
    operating-hours: (string-ascii 20),
    seasonal-closure: bool
  }
)

(define-map scheduled-visits
  { visit-id: uint }
  {
    visitor: principal,
    site-id: uint,
    visit-date: uint,
    group-size: uint,
    visit-type: (string-ascii 20),
    fee-paid: uint,
    status: (string-ascii 20),
    guide-assigned: (optional principal)
  }
)

(define-map daily-visitors
  { site-id: uint, date: uint }
  { visitor-count: uint, revenue: uint }
)

(define-map educational-programs
  { program-id: uint }
  {
    title: (string-utf8 200),
    description: (string-utf8 500),
    site-id: uint,
    instructor: principal,
    max-participants: uint,
    duration-hours: uint,
    program-fee: uint,
    schedule: (string-ascii 100)
  }
)

(define-map program-registrations
  { program-id: uint, participant: principal }
  {
    registration-date: uint,
    payment-status: (string-ascii 20),
    attendance-status: (string-ascii 20)
  }
)

(define-map program-participants
  { program-id: uint }
  {
    participants: (list 50 principal),
    participant-count: uint
  }
)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (calculate-daily-capacity (site-id uint) (date uint))
  (match (map-get? daily-visitors { site-id: site-id, date: date })
    daily-data (get visitor-count daily-data)
    u0
  )
)

(define-private (get-site-capacity (site-id uint))
  (match (map-get? site-access-rules { site-id: site-id })
    rules (get daily-capacity rules)
    u50 ;; default capacity
  )
)

;; Public Functions
(define-public (set-site-access-rules
  (site-id uint)
  (daily-capacity uint)
  (entry-fee uint)
  (access-restrictions (string-ascii 50))
  (operating-hours (string-ascii 20))
)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> site-id u0) ERR-INVALID-INPUT)
    (asserts! (> daily-capacity u0) ERR-INVALID-INPUT)

    (map-set site-access-rules
      { site-id: site-id }
      {
        daily-capacity: daily-capacity,
        entry-fee: entry-fee,
        access-restrictions: access-restrictions,
        operating-hours: operating-hours,
        seasonal-closure: false
      }
    )

    (ok true)
  )
)

(define-public (schedule-visit
  (site-id uint)
  (visit-date uint)
  (group-size uint)
  (visit-type (string-ascii 20))
)
  (let (
    (visit-id (var-get next-visit-id))
    (site-rules (unwrap! (map-get? site-access-rules { site-id: site-id }) ERR-INVALID-INPUT))
    (current-capacity (calculate-daily-capacity site-id visit-date))
    (entry-fee (get entry-fee site-rules))
    (total-fee (* entry-fee group-size))
  )
    (asserts! (> site-id u0) ERR-INVALID-INPUT)
    (asserts! (> visit-date block-height) ERR-INVALID-INPUT)
    (asserts! (> group-size u0) ERR-INVALID-INPUT)
    (asserts! (<= (+ current-capacity group-size) (get daily-capacity site-rules)) ERR-CAPACITY-EXCEEDED)
    (asserts! (not (get seasonal-closure site-rules)) ERR-INVALID-INPUT)

    ;; Create visit record
    (map-set scheduled-visits
      { visit-id: visit-id }
      {
        visitor: tx-sender,
        site-id: site-id,
        visit-date: visit-date,
        group-size: group-size,
        visit-type: visit-type,
        fee-paid: total-fee,
        status: "scheduled",
        guide-assigned: none
      }
    )

    ;; Update daily visitors
    (match (map-get? daily-visitors { site-id: site-id, date: visit-date })
      daily-data (map-set daily-visitors
        { site-id: site-id, date: visit-date }
        {
          visitor-count: (+ (get visitor-count daily-data) group-size),
          revenue: (+ (get revenue daily-data) total-fee)
        }
      )
      (map-set daily-visitors
        { site-id: site-id, date: visit-date }
        {
          visitor-count: group-size,
          revenue: total-fee
        }
      )
    )

    ;; Update counters
    (var-set next-visit-id (+ visit-id u1))
    (var-set total-visits (+ (var-get total-visits) u1))
    (var-set total-revenue (+ (var-get total-revenue) total-fee))

    (ok visit-id)
  )
)

(define-public (create-educational-program
  (title (string-utf8 200))
  (description (string-utf8 500))
  (site-id uint)
  (max-participants uint)
  (duration-hours uint)
  (program-fee uint)
  (schedule (string-ascii 100))
)
  (let (
    (program-id (var-get next-program-id))
  )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> site-id u0) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)

    ;; Create program record
    (map-set educational-programs
      { program-id: program-id }
      {
        title: title,
        description: description,
        site-id: site-id,
        instructor: tx-sender,
        max-participants: max-participants,
        duration-hours: duration-hours,
        program-fee: program-fee,
        schedule: schedule
      }
    )

    ;; Initialize participants
    (map-set program-participants
      { program-id: program-id }
      {
        participants: (list),
        participant-count: u0
      }
    )

    ;; Update counter
    (var-set next-program-id (+ program-id u1))

    (ok program-id)
  )
)

(define-public (register-for-program (program-id uint))
  (let (
    (program-data (unwrap! (map-get? educational-programs { program-id: program-id }) ERR-PROGRAM-NOT-FOUND))
    (participants-data (unwrap! (map-get? program-participants { program-id: program-id }) ERR-PROGRAM-NOT-FOUND))
  )
    (asserts! (< (get participant-count participants-data) (get max-participants program-data)) ERR-CAPACITY-EXCEEDED)
    (asserts! (is-none (map-get? program-registrations { program-id: program-id, participant: tx-sender })) ERR-INVALID-INPUT)

    ;; Create registration record
    (map-set program-registrations
      { program-id: program-id, participant: tx-sender }
      {
        registration-date: block-height,
        payment-status: "pending",
        attendance-status: "registered"
      }
    )

    ;; Update participants list
    (map-set program-participants
      { program-id: program-id }
      {
        participants: (unwrap! (as-max-len? (append (get participants participants-data) tx-sender) u50) ERR-INVALID-INPUT),
        participant-count: (+ (get participant-count participants-data) u1)
      }
    )

    (ok true)
  )
)

(define-public (update-visit-status (visit-id uint) (new-status (string-ascii 20)))
  (let (
    (visit-data (unwrap! (map-get? scheduled-visits { visit-id: visit-id }) ERR-VISIT-NOT-FOUND))
  )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (map-set scheduled-visits
      { visit-id: visit-id }
      (merge visit-data { status: new-status })
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-site-access-rules (site-id uint))
  (map-get? site-access-rules { site-id: site-id })
)

(define-read-only (get-scheduled-visit (visit-id uint))
  (map-get? scheduled-visits { visit-id: visit-id })
)

(define-read-only (get-daily-visitors (site-id uint) (date uint))
  (map-get? daily-visitors { site-id: site-id, date: date })
)

(define-read-only (get-educational-program (program-id uint))
  (map-get? educational-programs { program-id: program-id })
)

(define-read-only (get-program-participants (program-id uint))
  (map-get? program-participants { program-id: program-id })
)

(define-read-only (get-total-visits)
  (var-get total-visits)
)

(define-read-only (get-total-revenue)
  (var-get total-revenue)
)

(define-read-only (check-availability (site-id uint) (date uint) (group-size uint))
  (let (
    (current-capacity (calculate-daily-capacity site-id date))
    (site-capacity (get-site-capacity site-id))
  )
    (<= (+ current-capacity group-size) site-capacity)
  )
)
