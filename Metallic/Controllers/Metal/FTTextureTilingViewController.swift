//
//  FTTextureTilingViewController.swift
//  Metallic
//
//  Created by Akshay on 03/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import MetalKit
import PDFKit

let pdfFileName = "Digits"

class FTTextureTilingViewController: UIViewController {

    @IBOutlet weak var zoomItem : UIBarButtonItem?
    @IBOutlet weak var zoomStepper : UIStepper!
    @IBOutlet var toolbar : UIToolbar!

    private var scrollView : UIScrollView!
    private var metalView : MetalView!

    private var metalLayer: CAMetalLayer!
    private var renderer: TiledTextureRenderer!
    private var texture : MTLTexture!

    private let pdfURL = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf")!
    private var pdfPage: PDFPage!
    private var pageRect: CGRect = UIScreen.main.bounds;
    private var tileRects: [CGRect] = [CGRect]();

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePDFPage()
        configureUI()

        guard let layer = metalView.layer as? CAMetalLayer else {
            fatalError("Metal view did not setup")
        }
        self.metalLayer = layer
        renderer = TiledTextureRenderer(metalLayer: layer)
        let tiles = FTTextureCreation.tiles(forPage: pdfPage,
                                            tileRects: tileRects,
                                            scale: 1.0)
        renderer.renderTiles(textures: tiles)
    }

    func configureUI() {
        zoomItem?.title = "Zoom \(zoomStepper.value)"
        let minScale : CGFloat = 1.0
        let maxScale : CGFloat = 6.0

        let rect = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: self.view.bounds.height-toolbar.frame.height))

        scrollView = UIScrollView(frame: rect)
        scrollView.delegate = self
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = maxScale
        self.view.addSubview(scrollView)


        //Zoom Stepper
        zoomStepper.minimumValue = Double(minScale)
        zoomStepper.maximumValue = Double(maxScale)

        //Metal View
        metalView = MetalView(frame: scrollView.bounds)
        metalView.center = self.scrollView.center
        self.scrollView.addSubview(metalView)
    }

    @IBAction func zoomSelected(_ stepper: UIStepper) {

        zoomItem?.title = "Zoom \(stepper.value)"
       // scrollView.setZoomScale(CGFloat(stepper.value), animated: true)
        print("Zoom scale",Int(stepper.value))
        let scale = CGFloat(stepper.value)
//        let scaledRect = CGRectScale(rect: pageRect, scale: scale)
//        let rects = visibleTiles(scale: scale)
        let tiles = FTTextureCreation.tiles(forPage: pdfPage,
                                            tileRects: tileRects,
                                            scale: scale)
        renderer.renderTiles(textures: tiles)
    }

    func visibleTiles(scale: CGFloat) -> [CGRect] {
        let intersecting = tileRects.intersecting(with: pageRect, scale: scale)
        print("intersecting.count",intersecting.count)
        return intersecting
    }

    func configurePDFPage() {
        let pdf = PDFDocument(url: pdfURL)
        pdfPage = pdf?.page(at: 0)

        if let cgPDFPageRef = pdfPage.pageRef {
            pageRect = cgPDFPageRef.getBoxRect(CGPDFBox.cropBox);
            if(pageRect.size.width > 0 && pageRect.size.height > 0) {
                let transform = cgPDFPageRef.getDrawingTransform(CGPDFBox.cropBox, rect: pageRect, rotate: 0, preserveAspectRatio: true);
                pageRect = pageRect.applying(transform);
            }
        }
        pageRect.origin = CGPoint.zero;
        prepareTiles()
    }

    func prepareTiles() {
        let rows = 3
        let columns = 3
        let eachWidth = pageRect.width/CGFloat(rows);
        let eachHeight = pageRect.height/CGFloat(columns);

        tileRects.removeAll()

        for row in 0..<rows {
            for col in 0..<columns {
                let xOrigin = pageRect.width - CGFloat(col)*eachWidth;
                let yOrigin = pageRect.height - CGFloat(row)*eachHeight;
                let rect = CGRect(x: xOrigin, y: yOrigin, width: eachWidth, height: eachHeight);
                tileRects.append(rect)
            }
        }
        tileRects.reverse()
    }
}

extension FTTextureTilingViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return metalView
    }

//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        scrollView.setZoomScale(round(scale), animated: true)
//        zoomItem?.title = "Zoom \(scrollView.zoomScale)"
//        zoomStepper.value = Double(scrollView.zoomScale)
//        print("Zoom scale",scale)
//        let bounds = UIScreen.main.bounds
//        texture = FTTextureCreation.texture(forPage: pdfPage,
//                                            toFitIn: bounds,
//                                            scale: scrollView.zoomScale)
//    }
}


extension Sequence where Element == CGRect {
    func scaled(scale: CGFloat) -> [CGRect] {
        let _scaled = self.map({CGRectScale(rect: $0, scale: scale)})
        return _scaled
    }

    func intersecting(with rect: CGRect, scale: CGFloat) -> [CGRect] {
        let _intersects = self.scaled(scale: scale).filter({ $0.intersects(rect)})
        return _intersects
    }
}
