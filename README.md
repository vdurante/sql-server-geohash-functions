# SQL Server Geohash Functions

This repo contains SQL Server functions capable of encoding and decoding Geohashes.

## Installation 

Just execute the code from `geohash.sql` in your SQL Server database.


## Usage

### Encoding

```sql
SELECT dbo.geohash_encode(57.64911, 10.40744, 12)
-- u4pruydqqvjc
```

```sql
SELECT dbo.geohash_encode(57.64911, 10.40744, 8)
-- u4pruydq
```

### Decoding

Still not implemented.

## Credits

This code is heavily inspired by nowelium's [geohash-mysql-func](https://github.com/nowelium/geohash-mysql-func/blob/master/geohash.sql), with a few modifications to improve rounding of the decimal numbers.