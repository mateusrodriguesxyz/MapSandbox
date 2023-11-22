
// https://en.wikipedia.org/wiki/DBSCAN

public struct DBSCAN<Value: Equatable> {
    
    private class Point: Equatable {
        
        let value: Value
        var label: Int?
        
        init(_ value: Value) {
            self.value = value
        }
        
        static func == (lhs: Point, rhs: Point) -> Bool {
            return lhs.value == rhs.value
        }
    }
    
    public let values: [Value]
 
    public init(_ values: [Value]) {
        self.values = values
    }
    
    public func callAsFunction(epsilon: Double, minimumNumberOfPoints: Int, distance: (Value, Value) throws -> Double) rethrows -> (clusters: [[Value]], outliers: [Value]) {
                
        let points = values.map { Point($0) }
        
        var currentLabel = 0
        
        for point in points {
            guard point.label == nil else { continue }
            
            var neighbors = try points.filter { try distance(point.value, $0.value) < epsilon }
            if neighbors.count >= minimumNumberOfPoints {
                defer { currentLabel += 1 }
                point.label = currentLabel
                
                while !neighbors.isEmpty {
                    let neighbor = neighbors.removeFirst()
                    guard neighbor.label == nil else { continue }
                    
                    neighbor.label = currentLabel
                    
                    let n1 = try points.filter { try distance(neighbor.value, $0.value) < epsilon }
                    if n1.count >= minimumNumberOfPoints {
                        neighbors.append(contentsOf: n1)
                    }
                }
            }
        }
        
        var clusters: [[Value]] = []
        var outliers: [Value] = []
        
        for (label, points) in Dictionary(grouping: points, by: { $0.label }) {
            let values = points.map { $0.value }
            if label == nil {
                outliers.append(contentsOf: values)
            } else {
                clusters.append(values)
            }
        }
        
        return (clusters, outliers)
    }
}
