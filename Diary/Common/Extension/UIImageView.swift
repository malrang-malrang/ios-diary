//
//  UIImageView.swift
//  Diary
//
//  Created by mmim, grumpy, mino on 2022/06/23.
//

import UIKit

extension UIImageView {
    func loadImage(icon: String) -> URLSessionDataTask? {
        let cacheKey = NSString(string: icon)
        if let cacheImage = ImageCacheManager.shared.object(forKey: cacheKey) {
            self.image = cacheImage
            return nil
        }
        return RequestManager.shared.requestAPI(icon: icon) { [weak self] result in
            switch result {
            case .success(let image):
                ImageCacheManager.shared.setObject(image, forKey: cacheKey)
                DispatchQueue.main.async {
                    self?.image = image
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.image = UIImage(systemName: "questionmark.square.dashed")
                }
            }
        }
    }
}
