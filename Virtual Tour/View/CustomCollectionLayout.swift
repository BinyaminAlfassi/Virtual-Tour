//
//  CustomCollectionLayout.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 07/10/2020.
//

import Foundation
import UIKit

class CustomCollectionLayout: UICollectionViewFlowLayout {
    var numberOfItemsInRow: Int = 3 {
        didSet {
            invalidateLayout()
        }
    }
    
    override func prepare() {
        super.prepare()
        
        if let collectionView = self.collectionView {
            var newSize = itemSize
            
            //Making sure at list one item in a row
            let itemsInRow = CGFloat(max(numberOfItemsInRow, 1))
            
            // Sum of all spaces between items
            let totalSpace = minimumInteritemSpacing * (itemsInRow - 1.0)
            
            // Items Width
            newSize.width = (collectionView.bounds.size.width - sectionInset.left - sectionInset.right - totalSpace) / itemsInRow
            // Item Height
            if itemSize.height > 0 {
                let aspectRatio = itemSize.width / itemSize.height
                newSize.height = newSize.width / aspectRatio
            }
            
            // Setting the new item size
            itemSize = newSize
        }
    }
}
