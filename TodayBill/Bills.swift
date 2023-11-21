struct Bills: Codable {
    let nzmimeepazxkubdpn: [Nzmimeepazxkubdpn]
}

struct Nzmimeepazxkubdpn: Codable {
    let head: [Head]?
    let row: [Row]?
}

struct Head: Codable {
    let list_total_count: Int?
    let RESULT: Result?
}

struct Result: Codable {
    let CODE: String
    let MESSAGE: String
}

struct Row: Codable {
    let BILL_ID: String
    let BILL_NO: String
    let BILL_NAME: String
    let COMMITTEE: String?
    let PROPOSE_DT: String
    let PROC_RESULT: String?
    let AGE: String
    let DETAIL_LINK: String
    let PROPOSER: String
    let MEMBER_LIST: String
    let LAW_PROC_DT: String?
    let LAW_PRESENT_DT: String?
    let LAW_SUBMIT_DT: String?
    let CMT_PROC_RESULT_CD: String?
    let CMT_PROC_DT: String?
    let CMT_PRESENT_DT: String?
    let COMMITTEE_DT: String?
    let PROC_DT: String?
    let COMMITTEE_ID: String?
    let PUBL_PROPOSER: String
    let LAW_PROC_RESULT_CD: String?
    let RST_PROPOSER: String
}
