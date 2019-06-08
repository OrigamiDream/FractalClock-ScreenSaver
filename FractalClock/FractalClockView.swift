//
// Created by OrigamiDream on 2019-06-07.
// Copyright (c) 2019 OrigamiDream. All rights reserved.
//

import Cocoa
import ScreenSaver

class FractalClockView: ScreenSaverView {

    public var MAX_FRACTAL_DEPTH = 10
    public var SECONDS_PER_MINUTE = 6000.0
    
    public let CLOCK_CASE_RADIUS_RATIO: CGFloat = 0.7
    public let SECOND_HAND_LENGTH_RATIO: CGFloat = 0.65
    public let INDICATOR_DISTANCE_RATIO: CGFloat = 0.75
    public let DIVISION_DISTANCE_RATIO: CGFloat = 0.65
    public let FONT_SIZE_RATIO: CGFloat = 0.06
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        initialize()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        initialize()
    }
    
    private func initialize() {
        animationTimeInterval = 0.001
    }
    
    override func animateOneFrame() {
        setNeedsDisplay(bounds)
    }

    func createHand(_ time: Int, _ radius: Int) -> (CGFloat, CGFloat) {
        let angle: Double = 2 * .pi * Double(time) / SECONDS_PER_MINUTE
        return (CGFloat(cos(angle) * Double(radius)), CGFloat(sin(angle) * Double(radius)))
    }

    func drawFractal(_ previousGradient: Int, _ seconds: Int, _ minutes: Int, _ centerX: CGFloat, _ centerY: CGFloat, _ depth: Int, _ previousLength: Double) {
        let length = previousLength * 0.7
        
        let minuteHand = createHand(previousGradient + minutes - 1500, Int(length))
        let secondHand = createHand(previousGradient + seconds - 1500, Int(length))
        
        var strokeColor: NSColor
        if depth > 0 {
            let gradient = 510 / MAX_FRACTAL_DEPTH
            let blueGradient = 255 / MAX_FRACTAL_DEPTH
            
            strokeColor = NSColor(red: CGFloat(min(255, gradient * depth)) / 255, green: CGFloat(max(0, 255 - (gradient * depth))) / 255, blue: CGFloat(blueGradient * depth) / 255, alpha: 100 / 255)
        } else {
            strokeColor = .white
        }
        
        strokeColor.setStroke()
        drawLine(1.5, centerX, centerY, centerX + secondHand.0, centerY + secondHand.1)
        drawLine(2.0, centerX, centerY, centerX + minuteHand.0, centerY + minuteHand.1)
        
        if depth + 1 > MAX_FRACTAL_DEPTH {
            return
        }

        drawFractal(previousGradient + minutes, seconds, minutes, centerX + minuteHand.0, centerY + minuteHand.1, depth + 1, length)
        drawFractal(previousGradient + seconds, seconds, minutes, centerX + secondHand.0, centerY + secondHand.1, depth + 1, length)
    }
    
    private func drawLine(_ thickness: CGFloat, _ fromX: CGFloat, _ fromY: CGFloat, _ toX: CGFloat, _ toY: CGFloat) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: fromX, y: bounds.height - fromY))
        path.line(to: NSPoint(x: toX, y: bounds.height - toY))
        path.lineWidth = thickness
        path.stroke()
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        let backgroundColor: NSColor = .black
        backgroundColor.setFill()
        NSBezierPath.fill(bounds)
        
        let centerX = bounds.midX
        let centerY = bounds.midY
        
        let components = NSCalendar.current.dateComponents([ .hour, .minute, .second, .nanosecond ], from: Date())
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        let seconds = Double(components.second ?? 0)
        let milliseconds = Double((components.nanosecond ?? 0) / 1000000)
        
        let combined = minutes * 6000 + seconds * 100 + milliseconds / 10
        
        drawHourHand(hours, minutes, seconds)
        drawFractal(0, Int(combined), Int(combined / 60), centerX, centerY, 0, Double(SECOND_HAND_LENGTH_RATIO * (bounds.height / 2)))
        drawNumberFace()
        drawDivision()
    }
    
    private func drawNumberFace() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let clockWidth = CLOCK_CASE_RADIUS_RATIO * (bounds.height / 2)
        let textRadius = clockWidth
        let font = NSFont(name: "HelveticaNeue-Light", size: bounds.height / 2 * FONT_SIZE_RATIO)!
        
        for i in 0..<12 {
            let string = NSAttributedString(string: "\(12 - i)", attributes: [
                .foregroundColor: NSColor.white,
                .kern: -2,
                .font: font
            ])
            
            let stringSize = string.size()
            let angle = CGFloat((Double(i) / 12.0 * .pi * 2.0) + .pi / 2)
            let rect = CGRect(
                x: (center.x + cos(angle) * (textRadius - (stringSize.width / 2.0))) - (stringSize.width / 2.0),
                y: center.y + sin(angle) * (textRadius - (stringSize.height / 2.0)) - (stringSize.height / 2.0),
                width: stringSize.width,
                height: stringSize.height
            )
            
            string.draw(in: rect)
        }
    }
    
    private func drawHourHand(_ hours: Double, _ minutes: Double, _ seconds: Double) {
        let timing = seconds + minutes * 60.0 + hours * 60 * 60
        let minutesPerDay = 60.0 * 60.0 * 12.0
        
        let progress = Double(timing) / minutesPerDay
        let angle = CGFloat(-(progress * .pi * 2) + .pi / 2)
        
        let color = NSColor.white
        color.setStroke()
        
        let path = NSBezierPath()
        path.move(to: CGPoint(x: bounds.midX, y: bounds.midY))
        path.line(to: CGPoint(x: bounds.midX + cos(angle) * CGFloat(SECOND_HAND_LENGTH_RATIO * (bounds.height / 2) * 0.7), y: bounds.midY + sin(angle) * CGFloat(SECOND_HAND_LENGTH_RATIO * (bounds.height / 2) * 0.7)))
        path.lineWidth = 5.0
        path.stroke()
    }
    
    private func drawDivision() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        for i in 0..<60 {
            let isMajor = (i % 5) == 0
            let progress = Double(i) / 60.0
            let angle = CGFloat(-(progress * .pi * 2) + .pi / 2)
            
            let color = NSColor.white
            color.setStroke()
            
            let path = NSBezierPath()
            path.move(to: CGPoint(
                x: center.x + cos(angle) * CGFloat(INDICATOR_DISTANCE_RATIO * (bounds.height / 2) + 10),
                y: center.y + sin(angle) * CGFloat(INDICATOR_DISTANCE_RATIO * (bounds.height / 2) + 10)
            ))
            
            path.line(to: CGPoint(
                x: center.x + cos(angle) * CGFloat(CLOCK_CASE_RADIUS_RATIO * (bounds.height / 2) + (isMajor ? 10 : 5)),
                y: center.y + sin(angle) * CGFloat(CLOCK_CASE_RADIUS_RATIO * (bounds.height / 2) + (isMajor ? 10 : 5))
            ))
            
            path.lineWidth = isMajor ? 5.0 : 2.5
            path.stroke()
        }
    }
}
