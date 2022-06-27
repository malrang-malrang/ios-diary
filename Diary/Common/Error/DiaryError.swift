//
//  DiaryError.swift
//  Diary
//
//  Created by mmim, grumpy, mino on 2022/06/22.
//

import Foundation

enum DiaryError: LocalizedError {
    case loadFail
    case saveFail
    case networkError
    
    var errorDescription: String {
        switch self {
        case .loadFail:
            return "데이터를 불러오지 못했습니다."
        case .saveFail:
            return "데이터를 저장하지 못했습니다."
        case .networkError:
            return "서버와 통신하지 못했습니다."
        }
    }
}