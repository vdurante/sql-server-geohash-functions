CREATE OR ALTER FUNCTION geohash_bit(
    @_bit TINYINT
)
RETURNS TINYINT
AS
BEGIN
    DECLARE @bit TINYINT = NULL;

    RETURN CASE @_bit
        WHEN 0 THEN 16
        WHEN 1 THEN 8
        WHEN 2 THEN 4
        WHEN 3 THEN 2
        WHEN 4 THEN 1
        END
END
GO

CREATE OR ALTER FUNCTION geohash_base32 (
    @_index TINYINT
)
RETURNS CHAR(1)
AS
BEGIN

    RETURN CASE @_index
        WHEN 0 THEN '0'
        WHEN 1 THEN '1'
        WHEN 2 THEN '2'
        WHEN 3 THEN '3'
        WHEN 4 THEN '4'
        WHEN 5 THEN '5'
        WHEN 6 THEN '6'
        WHEN 7 THEN '7'
        WHEN 8 THEN '8'
        WHEN 9 THEN '9'
        WHEN 10 THEN 'b'
        WHEN 11 THEN 'c'
        WHEN 12 THEN 'd'
        WHEN 13 THEN 'e'
        WHEN 14 THEN 'f'
        WHEN 15 THEN 'g'
        WHEN 16 THEN 'h'
        WHEN 17 THEN 'j'
        WHEN 18 THEN 'k'
        WHEN 19 THEN 'm'
        WHEN 20 THEN 'n'
        WHEN 21 THEN 'p'
        WHEN 22 THEN 'q'
        WHEN 23 THEN 'r'
        WHEN 24 THEN 's'
        WHEN 25 THEN 't'
        WHEN 26 THEN 'u'
        WHEN 27 THEN 'v'
        WHEN 28 THEN 'w'
        WHEN 29 THEN 'x'
        WHEN 30 THEN 'y'
        WHEN 31 THEN 'z'
    END
END
GO

CREATE OR ALTER FUNCTION geohash_encode (
    @_latitude DECIMAL(10, 7),
    @_longitude DECIMAL(10, 7),
    @_precision TINYINT
)
-- TODO rollback
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @latL DECIMAL(10, 7) = -90.0
    DECLARE @latR DECIMAL(10, 7) = 90.0

    DECLARE @lonT DECIMAL(10, 7) = -180.0
    DECLARE @lonB DECIMAL(10, 7) = 180.0

    DECLARE @bit TINYINT = 0
    DECLARE @bit_pos TINYINT = 0
    DECLARE @ch CHAR(1) = ''
    DECLARE @ch_pos INT = 0
    DECLARE @mid DECIMAL(12, 8) = NULL

    DECLARE @even TINYINT = 1
    DECLARE @geohash VARCHAR(12) = ''
    DECLARE @geohash_length TINYINT = 0

    IF @_precision IS NULL
        SET @_precision = 12

    WHILE @geohash_length < @_precision
    BEGIN
        IF @even != 0
        BEGIN
            --
            -- is even
            --
            
            SET @mid = (@lonT + @lonB) / 2;
			
            SET @mid = ROUND(@mid, 7, 1);
			
            IF @mid < @_longitude
            BEGIN
                SET @bit = dbo.geohash_bit(@bit_pos);

                SET @ch_pos = @ch_pos | @bit;
                SET @lonT = @mid;
            END
            ELSE
            BEGIN
                SET @lonB = @mid;
            END            
        END
        ELSE
        BEGIN
            --
            -- not even
            --
            
            SET @mid = (@latL + @latR) / 2;
			
            SET @mid = ROUND(@mid, 7, 1);
			
            IF @mid < @_latitude 
            BEGIN
                SET @bit = dbo.geohash_bit(@bit_pos);

                SET @ch_pos = @ch_pos | @bit;
                SET @latL = @mid;
            END
            ELSE
            BEGIN
                SET @latR = @mid
            END
        END

        -- toggle even
        IF @even = 0
            SET @even = 1
        ELSE
            SET @even = 0

        IF @bit_pos < 4
            SET @bit_pos = @bit_pos + 1;
        ELSE
        BEGIN
            SET @ch = dbo.geohash_base32(@ch_pos);

            SET @geohash = CONCAT(@geohash, @ch);
            SET @bit_pos = 0;
            SET @ch_pos = 0;
        END

        SET @geohash_length = LEN(@geohash);
    END

    RETURN @geohash
END
GO