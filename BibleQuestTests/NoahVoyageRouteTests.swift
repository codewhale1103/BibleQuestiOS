import Foundation
import Testing
@testable import BibleQuest

struct NoahVoyageRouteTests {
    @Test(arguments: [320.0,390,768,1024])
    func routePassesThroughEveryChapterAtEveryLayoutWidth(width: Double) {
        let route = NoahVoyageRoute(width: width)
        for index in 0..<7 {
            let p = route.point(NoahVoyageRoute.progress(for: index)),stop = route.stop(index)
            #expect(abs(p.x-stop.x) < 0.00001)
            #expect(abs(p.y-stop.y) < 0.00001)
            #expect(route.index(at: NoahVoyageRoute.progress(for: index)) == index)
            #expect(p.x > 25 && p.x < width-25)
        }
    }
    @Test func headingFollowsTheCurveAndTheShipStaysClearOfTheBeacons() {
        let route = NoahVoyageRoute(width: 390)
        for index in 0...600 {
            let progress = Double(index)/600
            let direction = route.tangent(progress)
            #expect(direction.dx.isFinite && direction.dy.isFinite)
            #expect(abs(hypot(direction.dx,direction.dy)-1) < 0.00001)
            #expect(direction.dy > 0)
            #expect(abs(route.heading(progress)) < 0.7)
            let ship = route.arkPoint(progress),point = route.point(progress)
            #expect(abs(hypot(ship.x-point.x,ship.y-point.y)-108) < 0.00001)
            #expect(ship.y < point.y)
        }
    }
    @Test func curveAndHeadingRemainContinuousAcrossAllHarbors() {
        let route = NoahVoyageRoute(width: 430)
        var last = route.point(0)
        for index in 1...600 {
            let point = route.point(Double(index)/600)
            #expect(point.y > last.y)
            #expect(hypot(point.x-last.x,point.y-last.y) < 9)
            last = point
        }
        for index in 1..<6 {
            let p = NoahVoyageRoute.progress(for: index)
            #expect(abs(route.heading(p-0.00001)-route.heading(p+0.00001)) < 0.001)
        }
    }
    @Test func invalidAndOutOfRangeProgressCannotEscapeTheMap() {
        let route = NoahVoyageRoute(width: .nan)
        #expect(route.point(.nan) == route.stop(0))
        #expect(route.point(-1) == route.stop(0))
        #expect(route.point(5) == route.stop(6))
        #expect(route.index(at: .infinity) == 0)
        #expect(NoahVoyageRoute.progress(for: -3) == 0)
        #expect(NoahVoyageRoute.progress(for: 20) == 1)
    }
    @Test func sevenChaptersHaveDistinctStoriesAndTheOriginalOrder() {
        #expect(NoahVoyageChapter.allCases.count == 7)
        #expect(NoahVoyageChapter.allCases.map(\.id) == Array(0..<7))
        #expect(NoahVoyageChapter.call.title == "God’s Call")
        #expect(NoahVoyageChapter.promise.title == "Rainbow Promise")
        #expect(Set(NoahVoyageChapter.allCases.map(\.story)).count == 7)
        #expect(NoahVoyageChapter.allCases.allSatisfy { !$0.passage.isEmpty && !$0.subtitle.isEmpty })
    }
}
