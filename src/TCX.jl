function parse_tcx_file(file::String)
    file_path = abspath(file)
    if isfile(file_path) == false
        return 404, nothing
    end
    xmldoc = try readxml(file_path)
    catch e
       if isa(e, EzXML.XMLError)
           # Not a valid XML document
           @warn "Invalid XML document: $file_path"
           return 400, nothing
       else
           return 500, nothing
       end
    end

    root_element = root(xmldoc)
    # Check if TCX
    if nodename(root_element) != "TrainingCenterDatabase"
        @warn "Invalid TCX document: $file_path"
        return 400, nothing
    end

    # Type - "/*/*[1]/*[1]/@Sport"
    aType = nodecontent(findfirst("/*/*[1]/*[1]/@Sport", xmldoc))  
    # Id - "/*/*[1]/*/*[1]"
    xid = nodecontent(findfirst("/*/*[1]/*/*[1]", xmldoc))

    aId = convertToDateTime(xid)
    # Name = "/*/*[1]/*[1]/*[3]"
    aName = nodecontent(findfirst("/*/*[1]/*/*[2]", xmldoc))
    # Lap - "/*/*[1]/*/*[2]"
    # TotalSeconds - "/*/*[1]/*/*[2]/*[1]"
    aTime = parse(Float64, nodecontent(findfirst("/*/*[1]/*/*[2]/*[1]", xmldoc)))
    aDistance = parse(Float64, nodecontent(findfirst("/*/*[1]/*/*[2]/*[2]", xmldoc)))
    # DistanceMeters - "/*/*[1]/*/*[2]/*[2]"
    # AverageHeartRateBpm - "/*/*[1]/*/*[2]/*[5]/*[1]"
    xbpm = findfirst("/*/*[1]/*/*[2]/*[5]/*[1]", xmldoc) 
    if xbpm === nothing
        aHeartRateBpm = 0
    else
        aHeartRateBpm = parse(Int32, nodecontent(xbpm))
    end
    # TrackPoints - "/*/*[1]/*/*[2]/*[9]/*"
    tp_Points = findall("/*/*[1]/*/*[2]/*[9]/*", xmldoc)   
    aTrackPoints = Array{TrackPoint, size(tp_Points, 1)}[]
    for tp in tp_Points
        xtime = nodecontent(findfirst("./*[local-name()='Time']", tp))
        tp_time = convertToDateTime(xtime)

        tp_lat = parseNode(Float64, "./*[local-name()='Position']/*[local-name()='LatitudeDegrees']", tp)
 
        tp_lont = parse(Float64, nodecontent(findfirst("./*[local-name()='Position']/*[local-name()='LatitudeDegrees']", tp)))
 
        tp_bpm = parseNode(Int32, "./*[local-name()='HeartRateBpm']/*[1]", tp)
        tp_dist = parseNode(Float64, "./*[local-name()='TPX']", tp)
        tp_alt = parseNode(Float64, "./*[local-name()='AltitudeMeters']", tp)

        aTrackPoints = vcat(aTrackPoints, TrackPoint(tp_time, tp_lat, tp_lont, tp_bpm, tp_dist, tp_alt))
    end

    return 200, TCXRecord(aId, aName, aType, aDistance, aTime, aHeartRateBpm, aTrackPoints)
end

function parseNode(dType, path, node)
    node_check = findfirst(path, node)
    if node_check !== nothing
        return parse(dType, nodecontent(node_check))
    else
        return dType(0)
    end
end
