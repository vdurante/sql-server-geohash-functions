# SQL Server Geohash Functions

This repo contains SQL Server functions capable of encoding and decoding Geohashes.

## Installation 

Just execute the code from `geohash.sql` in your SQL Server database.


## Usage

### Encoding

```sql
SELECT dbo.geohash_encode(57.64911, 10.40744, 12)
-- u4pruydqqvj8
```

```sql
SELECT dbo.geohash_encode(57.64911, 10.40744, 8)
-- u4pruydq
```

### Decoding

Decoding a Geohash will return a table with a single row with following columns:

* LatL - Left Latitude
* LatR - Right Latitude
* LngT - Top Longitude
* LngB - Bottom Longitude
* LatC - Center Latitude
* LngC - Center Longitude
* LatError - Latitude Error
* LngError - Longitude Error

Example:

```sql
SELECT LatL, LatR, LngT, LngB, LatC, LngC, LatError, LngError FROM dbo.geohash_decode('u4pruyd')
-- 57.6480103	57.6493836	10.4067994	10.4081727	57.6486970	10.4074861	0.0006867	0.0006867
```

Using columns from a table:

```sql
SELECT t.Geohash, d.LatL, d.LatR, d.LngT, d.LngB, d.LatC, d.LngC, d.LatError, d.LngError FROM MyTable t CROSS APPLY dbo.geohash_decode(t.Geohash) d
```

## Credits

* The `geohash_bit`, `geohash_base32` and `geohash_base32_index` functions were implemented using nowelium's [geohash-mysql-func](https://github.com/nowelium/geohash-mysql-func/blob/master/geohash.sql) as a reference
* The `geohash_encode` and `geohash_decode` functions were implemented using davetroy's [geohash-js](https://github.com/davetroy/geohash-js) as a reference