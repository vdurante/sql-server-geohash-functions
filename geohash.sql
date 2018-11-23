CREATE FUNCTION [dbo].[geohash_bit](
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

CREATE FUNCTION [dbo].[geohash_base32] (
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

CREATE FUNCTION [dbo].[geohash_base32_index] (
    @_ch CHAR(1)
)
RETURNS TINYINT
AS
BEGIN
    RETURN CASE @_ch
        WHEN '0' THEN 0
        WHEN '1' THEN 1
        WHEN '2' THEN 2
        WHEN '3' THEN  3
        WHEN '4' THEN 4
        WHEN '5' THEN 5
        WHEN '6' THEN 6
        WHEN '7' THEN 7
        WHEN '8' THEN 8
        WHEN '9' THEN 9
        WHEN 'b' THEN 10
        WHEN 'c' THEN 11
        WHEN 'd' THEN 12
        WHEN 'e' THEN 13
        WHEN 'f' THEN 14
        WHEN 'g' THEN 15
        WHEN 'h' THEN 16
        WHEN 'j' THEN 17
        WHEN 'k' THEN 18
        WHEN 'm' THEN 19
        WHEN 'n' THEN 20
        WHEN 'p' THEN 21
        WHEN 'q' THEN 22
        WHEN 'r' THEN 23
        WHEN 's' THEN 24
        WHEN 't' THEN 25
        WHEN 'u' THEN 26
        WHEN 'v' THEN 27
        WHEN 'w' THEN 28
        WHEN 'x' THEN 29
        WHEN 'y' THEN 30
        WHEN 'z' THEN 31
    END
END
GO


CREATE FUNCTION [dbo].[geohash_encode] (
    @_latitude DECIMAL(10, 7),
    @_longitude DECIMAL(10, 7),
    @_precision TINYINT
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @is_even TINYINT = 1
    DECLARE @i TINYINT = 0

    DECLARE @latL DECIMAL(38, 35) = -90.0
    DECLARE @latR DECIMAL(38, 35) = 90.0

    DECLARE @lonT DECIMAL(38, 34) = -180.0
    DECLARE @lonB DECIMAL(38, 34) = 180.0

    DECLARE @bit INT = 0
    DECLARE @ch INT = 0

    DECLARE @mid DECIMAL(12, 8) = NULL
    
    DECLARE @geohash VARCHAR(12) = ''

    IF @_precision IS NULL
        SET @_precision = 12

    WHILE LEN(@geohash) < @_precision
    BEGIN
        IF @is_even = 1
        BEGIN
            SET @mid = (@lonT + @lonB) / 2;
			
            --SET @mid = ROUND(@mid, 7, 1);
			
            IF @_longitude > @mid
            BEGIN
                SET @ch = @ch | dbo.geohash_bit(@bit)
                SET @lonT = @mid;
            END
            ELSE
            BEGIN
                SET @lonB = @mid;
            END            
        END
        ELSE
        BEGIN
            SET @mid = (@latL + @latR) / 2;

            --SET @mid = ROUND(@mid, 7, 1);
			
            IF @mid < @_latitude 
            BEGIN
                SET @ch = @ch | dbo.geohash_bit(@bit);
                SET @latL = @mid;
            END
            ELSE
            BEGIN
                SET @latR = @mid
            END
        END

        IF @is_even = 0
            SET @is_even = 1
        ELSE
            SET @is_even = 0

        IF @bit < 4
            SET @bit = @bit + 1;
        ELSE
        BEGIN
            SET @geohash = CONCAT(@geohash, dbo.geohash_base32(@ch));
            SET @bit = 0;
            SET @ch = 0;
        END
    END

    RETURN @geohash
END
GO

CREATE FUNCTION [dbo].[geohash_decode] (
    @_geohash VARCHAR(12)
)
RETURNS @result TABLE(
    LatL DECIMAL(10, 7),
    LatR DECIMAL(10, 7),
    LngT DECIMAL(10, 7),
    LngB DECIMAL(10, 7),
    LatC DECIMAL(10,7),
    LngC DECIMAL(10, 7),
    LatError DECIMAL(10,7),
    LngError DECIMAL(10, 7)
)
AS
BEGIN
    DECLARE @is_even bit = 1
    DECLARE @latL DECIMAL(10,7) = -90.0
    DECLARE @latR DECIMAL(10,7) = 90.0
    DECLARE @latC DECIMAL(10,7)
    DECLARE @lonT DECIMAL(10,7) = -180
    DECLARE @lonB DECIMAL(10,7) = 180
    DECLARE @lonC DECIMAL(10,7)

    DECLARE @lat_err DECIMAL(10,7) = 90.0
    DECLARE @lon_err DECIMAL(10,7) = 180.0

    DECLARE @i tinyint = 0
    DECLARE @len tinyint = LEN(@_geohash)

    DECLARE @c CHAR(1) = ''
    DECLARE @cd TINYINT = 0

    DECLARE @j TINYINT = 0

    DECLARE @mask TINYINT = 0
    DECLARE @masked_val TINYINT = 0

    WHILE @i < @len
    BEGIN
        SET @c = SUBSTRING(@_geohash, @i + 1, 1)

        SET @cd = dbo.geohash_base32_index(@c)

        SET @j = 0

        WHILE @j < 5
        BEGIN
            SET @mask = dbo.geohash_bit(@j)
            SET @masked_val = @cd & @mask

            IF @is_even = 1
            BEGIN
                SET @lon_err = @lon_err / 2

                IF @masked_val != 0
                    SET @lonT = (@lonT + @lonB) / 2
                ELSE
                    SET @lonB = (@lonT + @lonB) / 2
            END
            ELSE
            BEGIN
                SET @lat_err = @lat_err / 2

                IF @masked_val != 0
                    SET @latL = (@latL + @latR) / 2
                ELSE
                    SET @latR = (@latL + @latR) / 2
            END

            IF @is_even = 0
                SET @is_even = 1
            ELSE
                SET @is_even = 0

            SET @j = @j + 1
        END

        SET @i = @i + 1
    END

    SET @latC = (@latL + @latR) / 2
    SET @lonC = (@lonT + @lonB) / 2

    INSERT @result
    SELECT @latL, @latR, @lonT, @lonB, @latC, @lonC, @lat_err, @lon_err
    RETURN
END
GO
