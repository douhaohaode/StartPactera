//
//  downloadViewModel.swift
//  Yamoto
//
//  Created by pactera on 2020/12/3.
//  Copyright © 2020 pactera. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Alamofire
import RxDataSources


protocol downloadViewModelInputs {
    
    func pause(index : IndexPath)
    
    func start(index : IndexPath)
    
    func goOn(index : IndexPath)
}

protocol downloadViewModelOuputs {
    
    var models: BehaviorRelay<[DownLoadSection]> {get}
    
    func fetchData() -> Driver<[DownLoadSection]>
    
}

protocol downloadViewModelType {
    
    var inputs : downloadViewModelInputs { get }
    var output : downloadViewModelOuputs { get }
}


class DownloadViewModel:NSObject,downloadViewModelType,downloadViewModelInputs,downloadViewModelOuputs{
    
    var inputs: downloadViewModelInputs { return self }
    
    var output: downloadViewModelOuputs { return self }
    
    ///数据序列
    var models = BehaviorRelay<[DownLoadSection]>(value: [])
    
    ///数据集合
    var requests : DownLoadSection?
    
    ///自定义队列
    let progressQueue = DispatchQueue(label: "com.alamofire.progressQueue", qos: .utility , attributes: .concurrent)
    
    ///初始化数据
    func fetchData() -> Driver<[DownLoadSection]> {
        
        let list = ["list" : [
            ["title":"第一条.dmg" , "url" : "http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg" , "progress" : 0.0],
            ["title":"第二条.png" , "url" : "https://seopic.699pic.com/photo/50043/9886.jpg_wh1200.jpg" , "progress" : 0.0],
            ["title":"第三条.pptx" , "url" : "https://gmxjjzapi.dkvet.com/pactera.mp4" , "progress" : 0.0],
            ["title":"fdfsd.pptx" , "url" : "http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg" , "progress" : 0.0],
            ["title":"fdfsd.pptx" , "url" : "http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg" , "progress" : 0.0],
            ["title":"fdfsd.pptx" , "url" : "http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg" , "progress" : 0.0],]]
        
        requests   =  DownLoadSection(JSON: list)!
        models.accept([DownLoadSection(JSON: list)!])
        return models.asDriver()
    }
    
    ///开始
    func start(index: IndexPath){
        
        let items =  models.value.first?.items
        let  model = items![index.row]
        requests?.list![index.row].state  =    .pause

        let destinsation :  DownloadRequest.Destination =  { _, _ in
            let docmentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docmentsURL.appendingPathComponent(model.title)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        self.requests?.list![index.row].request  =
            AF.download(URL(string: model.url)!,to: destinsation)
                .downloadProgress (queue: progressQueue)
                { progress in
                    print("当前进度: \(progress.fractionCompleted)   当前标示 \(index.row)")
                    //print("  已下载：\(progress.completedUnitCount/1024)KB")
                    //  print("  总大小：\(progress.totalUnitCount/1024)KB")
                    self.requests?.list![index.row].progress  =    progress.fractionCompleted
                    self.requests?.list![index.row].state  =     .pause
                    
                    if progress.fractionCompleted == 1.0{
                        self.requests?.list![index.row].state   = .complete
                    }
                    self.models.accept([self.requests!])
            }
            .response { response in
                debugPrint(response)
        }
        self.models.accept([self.requests!])
    }
    
    ///暂停
    func pause(index: IndexPath) {
        
        self.requests?.list![index.row].state  = .continu
        self.requests?.list![index.row].request.suspend()
        self.models.accept([self.requests!])
    }
    
    ///继续
    func goOn(index: IndexPath) {
        
        self.requests?.list![index.row].state  = .pause
        self.requests?.list![index.row].request.resume()
        self.models.accept([self.requests!])
    }
    
    
}
