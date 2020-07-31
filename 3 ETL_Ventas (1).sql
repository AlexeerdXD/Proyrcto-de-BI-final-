use alexeerd_project_dmart_v;
SET lc_time_names = 'es_ES';
SET sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- DPRODUCTO----------->
INSERT INTO DPRODUCTO ( -- L = CARGA----------->
	Cod_prod,
    Nom_prod,
    Cat_prod,
    PreCom_prod,
    PreVent_prod
)
-- use alexeerd_proyectolaravel;
SELECT Cod_Producto,Nom_Producto,Nom_Categoria, Prec_Compra, Prec_Venta FROM (
	SELECT -- E = EXTRACCIÓN
	   -- T = TRANSFORMACIÓN
		p.codigo as Cod_Producto,
		p.nombre as Nom_Producto,
		c.nombre as Nom_Categoria,
		dc.precio as Prec_Compra,
		p.precio_venta as Prec_Venta
	FROM alexeerd_proyectolaravel.productos as p
		INNER JOIN alexeerd_proyectolaravel.detalle_compras as dc on p.id = dc.idproducto
		INNER JOIN alexeerd_proyectolaravel.categorias as c on p.idcategoria = c.id) AS REPORTE
    GROUP BY Cod_Producto,Nom_Producto,Nom_Categoria; 
-- DTIEMPO----------->
INSERT INTO DTIEMPO(
	Fecha,
    Dia_sem,
    Mes_cod,
    Mes_des,
    Trim_cod,
    Trim_des,
    Anio
)
SELECT 
	DATE_FORMAT(v.created_at, '%Y-%m-%d') as Fecha,
	DAYNAME(v.created_at) as Dia_Semana,
	MONTH(v.created_at) as Cod_Mes,
	MONTHNAME(v.created_at) as Des_Mes,
	QUARTER(v.created_at) as Cod_Trimestre,
	CONCAT('Trimestre ', QUARTER(v.created_at)) as Des_Trimestre,
	YEAR(v.created_at) as Cod_Año
FROM alexeerd_proyectolaravel.ventas as v WHERE v.created_at IS NOT NULL;
-- DVENDEDOR----------->	
INSERT INTO DVENDEDOR(
	Nom_ven,
    Dir_ven,
    Tel_ven,
    Ema_ven
)
SELECT 
    vd.nombre as Nom_Vendedor,
    vd.direccion as Dirección,
    vd.telefono as Telefono,
    vd.email as Email
FROM alexeerd_proyectolaravel.users as vd;
-- DCLIENTE----------->	
INSERT INTO DCLIENTE(
	Nom_cli,
    Dir_cli,
    Tel_cli,
    Ema_cli
)
SELECT
	cl.nombre as Nom_Cliente,
    cl.direccion as Dirección,
    cl.telefono as Telefono,
    cl.email as Email
FROM alexeerd_proyectolaravel.clientes as cl;
-- HVENTA----------->	
INSERT INTO HVENTA (
	DProducto_id,
    DTiempo_id,
    DVendedor_id,
    DCliente_id,
    Ventas,
    Vent_Cant_Prod,
    Costos,
    Descuento,
    Can_clientes
)
-- use alexeerd_project_dmart_v;
SELECT
	DP.DProducto_id, 
    DT.DTiempo_id,
    DV.DVendedor_id,
    DC.DCliente_id,
    SUM(G.Ventas) as VENTAS, 
    sum(G.Costos) as COSTOS,
    SUM(G.Vent_Cant_Prod) as CANT_UNID,
    SUM(G.Descuento) as DESCTOS,
    COUNT(DISTINCT G.Nom_cli) as Can_clientes
FROM (
-- use alexeerd_proyectolaravel;
	SELECT
    idventa,
		DATE_FORMAT(ve.created_at, '%Y-%m-%d') AS Fecha, 
        p.codigo as Cod_prod,
		p.nombre as Nom_Producto,
		c.nombre as Cat_Producto,
		dv.cantidad as Vent_Cant_Prod,
        dv.cantidad * dv.precio_compra as Costos,
        dv.cantidad * (dv.precio - dv.descuento) as Ventas,
        dv.cantidad * (dv.descuento) as Descuento,
        cli.nombre as Nom_cli,
        v.nombre as Nom_ven
	FROM alexeerd_proyectolaravel.ventas as ve 
		INNER JOIN alexeerd_proyectolaravel.detalle_ventas as dv on ve.id = dv.idventa
        INNER JOIN alexeerd_proyectolaravel.productos as p on dv.idproducto = p.id 
        INNER JOIN alexeerd_proyectolaravel.categorias as c on p.idcategoria = c.id
        INNER JOIN alexeerd_proyectolaravel.clientes as cli on ve.idcliente = cli.id 
        INNER JOIN alexeerd_proyectolaravel.users as v on ve.idusuario = v.id
) as G 
INNER JOIN DPRODUCTO as DP on G.Cod_prod = DP.Cod_prod
INNER JOIN DTIEMPO as DT on G.Fecha = DT.Fecha
INNER JOIN DCLIENTE as DC on G.Nom_cli = DC.Nom_cli
INNER JOIN DVENDEDOR as DV on G.Nom_ven = DV.Nom_ven
GROUP BY DP.DProducto_id, DT.DTiempo_id, DC.DCliente_id, DV.DVendedor_id;