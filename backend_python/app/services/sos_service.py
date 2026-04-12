def is_location(lat1,lat2,lon1,lon2):
    lat_diff=abs(lat1,lat2)
    lon_diff=abs(lon1,lon2)
    if(lat_diff< 0.009 and lon_diff<0.009):
        return True
    return False
def get_cluster(reports):
    aavg_lat=sum(r['lat'] for r in reports)/len(reports)
    aavg_lon=sum(r['lon'] for r in reports)/len(reports)
    return aavg_lat,aavg_lon

