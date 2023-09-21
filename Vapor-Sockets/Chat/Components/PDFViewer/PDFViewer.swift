//
//  PDFViewer.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 20/09/23.
//
import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {

    let pdfDocument: PDFDocument

    init(showing pdfDoc: PDFDocument) {
        self.pdfDocument = pdfDoc
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
}

struct PDFUIView: View {
    @Binding var showPDF: Bool
    let pdfDoc: PDFDocument
    let data: Data
    var title: String = ""
    
    init(showPDF: Binding<Bool>, data: Data) {
        self._showPDF = showPDF
        self.data = data
        pdfDoc = PDFDocument(data: self.data)!
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Spacer()
                    Text(title)
                    Spacer()
                    Button {
                        showPDF.toggle()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }.padding(.all)
                }
                PDFKitView(showing: pdfDoc)
            }
        }
    }
}
