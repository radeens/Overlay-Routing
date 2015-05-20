class Graph
    def initialize()
        @vertices = {}
    end

    def add_vertex(vertex, edges)
        @vertices[vertex] = edges
    end

    def add_graph(hash)
        hash.keys.each{|key|
            add_vertex(key,hash[key])
        }        
    end

    def add_edge(vertex1, vertex2, weight)
        if (@vertices[vertex1] == nil)
            add_vertex(vertex1, {})
        end
        
        if(@vertices[vertex2] == nil)
            add_vertex(vertex2, {})
        end

        @vertices[vertex1].store(vertex2, weight)
        @vertices[vertex2].store(vertex1, weight)
    end

    def remove_vertex(vertex)
        @vertices.delete(vertex)
        @vertices.each{|k,v|
            @vertices[k].delete(vertex)
        }
    end

    def remove_edge(vertex1, vertex2)
        @vertices[vertex1].delete(vertex2)
        @vertices[vertex2].delete(vertex1)
    end

    def to_s
        return @vertices.inspect
    end

    def shortest_path(src, dest)
        nodes = {}
        previous = {}
        @min_cost = {}
        infinity = 999999999
        
        #initialization for dijkstra's algorithm
        @vertices.each do | key, value |
            if key == src
                @min_cost[key] = 0
                nodes[key] = 0
            else
                @min_cost[key] = infinity
                nodes[key] = infinity
            end
            previous[key] = nil
        end
        
        #find the shortest path from src to dest
        while !(nodes.empty?)
            min = nodes.key(nodes.values.sort.first)
            nodes.delete(min)
            
            if min == dest
                path = []
                while previous[min]
                    path.push(min)
                    min = previous[min]
                end
                return path
            end
            
            if min == nil or @min_cost[min] == infinity
                break            
            end
            
            @vertices[min].each do | neighbor, value |
                cost = (@min_cost[min]).to_i + (@vertices[min][neighbor]).to_i
                if cost < (@min_cost[neighbor]).to_i
                    @min_cost[neighbor] = cost
                    previous[neighbor] = min
                    nodes[neighbor] = cost
                end
            end
        end
        return @min_cost.inspect
    end

    def get_costs
        return @min_cost
    end
    def get_routing(node)
        @table = Hash.new
        @vertices.keys.each{|vertex|
            nextHop         = shortest_path(node, vertex).reverse[0]
            cost            = get_costs[vertex]
            @table[vertex]  = [node, nextHop, cost]
            @table[node]    = [node, node, 0]
        }
        @table
    end
end

=begin
g = Graph.new

g.add_vertex('A', {'B' => 7, 'C' => 8})
g.add_vertex('B', {'A' => 7, 'F' => 2})
g.add_vertex('C', {'A' => 8, 'F' => 6, 'G' => 4})
g.add_vertex('D', {'F' => 8})
g.add_vertex('E', {'H' => 1})
g.add_vertex('F', {'B' => 2, 'C' => 6, 'D' => 8, 'G' => 9, 'H' => 3})
g.add_vertex('G', {'C' => 4, 'F' => 9})
g.add_vertex('H', {'E' => 1, 'F' => 3})
puts g.shortest_path('A', 'H').to_s
=end