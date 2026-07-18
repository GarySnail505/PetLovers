-- creacion
CREATE DATABASE PetLoversCentral COLLATE Modern_Spanish_CI_AS
go
use PetLoversCentral
go

--- Creacion de tablas
create table Sede
(
Codigo_sede char(3) not null,
Ubicacion varchar(50) not null,
Nombre_sede varchar(50) not null
)

create table Empleado
(
Codigo_empleado char(3) not null,
Cedula_empleado char(10) not null,
Nombre_empleado varchar(50) not null,
Celular_empleado char(10) not null,
Correo_empleado varchar(100) not null,
Cargo varchar(50) not null,
Codigo_sede char(3) not null
)

create table Cliente
(
Cedula_cliente char(10) not null,
Nombre_Cliente varchar(50) not null,
Celular_Cliente char(10) not null,
Correo_Cliente varchar(100) not null
)

create table Servicio
(
Codigo_servicio char(3) not null,
Tipo_servicio varchar(50) not null,
Costo_base numeric(7,2) not null,
Descripcion varchar(100) not null,
Codigo_sede char(3) not null
)

create table Mascota
(
Id_mascota char(3) not null,
Nombre_mascota varchar(50) not null,
Fecha_nacimiento date not null,
Especie varchar(30) not null,
Raza varchar(50) not null,
Cedula_cliente char(10) not null
)

create table Historial
(
Id_historial char(3) not null,
Id_mascota char(3) not null,
Codigo_servicio char(3) not null,
Codigo_empleado char(3) not null,
Fecha_atencion date not null,
Pago numeric(7,2) not null
)


------ Creacion de claves
select * from Sede
alter table Sede add constraint pk_codigo_sede primary key (Codigo_sede)

select * from Empleado
alter table Empleado add constraint pk_codigo_empleado primary key (Codigo_empleado)
alter table Empleado add constraint fk_codigo_sede_empleado foreign key (Codigo_sede) references Sede(Codigo_sede)

select * from Cliente
alter table Cliente add constraint pk_cedula_cliente primary key (Cedula_cliente)

select * from Servicio
alter table Servicio add constraint pk_codigo_servicio primary key (Codigo_servicio)
alter table Servicio add constraint fk_codigo_sede_servicio foreign key (Codigo_sede) references Sede(Codigo_sede)

select * from Mascota
alter table Mascota add constraint pk_id_mascota primary key (Id_mascota)
alter table Mascota add constraint fk_cedula_cliente_mascota foreign key (Cedula_cliente) references Cliente(Cedula_cliente)

select * from Historial
alter table Historial add constraint pk_id_historial primary key (Id_historial)
alter table Historial add constraint fk_id_mascota_historial foreign key (Id_mascota) references Mascota(Id_mascota)
alter table Historial add constraint fk_codigo_servicio_historial foreign key (Codigo_servicio) references Servicio(Codigo_servicio)
alter table Historial add constraint fk_codigo_empleado_historial foreign key (Codigo_empleado) references Empleado(Codigo_empleado)


--- Ingreso de datos
insert into Sede values ('001','Cumbaya','PetLovers Cumbaya')
insert into Sede values ('002','Inaquito','PetLovers Inaquito')

insert into Empleado values ('E01','1711111111','Ana Torres','0991111111','ana.torres@petlovers.ec','Veterinaria general','001')
insert into Empleado values ('E02','1722222222','Carlos Mena','0992222222','carlos.mena@petlovers.ec','Estilista canino','001')
insert into Empleado values ('E03','1733333333','Lucia Paz','0993333333','lucia.paz@petlovers.ec','Auxiliar veterinaria','001')
insert into Empleado values ('E04','1744444444','Miguel Leon','0994444444','miguel.leon@petlovers.ec','Cirujano veterinario','002')
insert into Empleado values ('E05','1755555555','Sofia Ruiz','0995555555','sofia.ruiz@petlovers.ec','Traumatologa veterinaria','002')
insert into Empleado values ('E06','1766666666','Diego Mora','0996666666','diego.mora@petlovers.ec','Administrador','002')

insert into Cliente values ('1712345678','Juan Perez','0981111111','juan.perez@email.com')
insert into Cliente values ('1723456789','Maria Lopez','0982222222','maria.lopez@email.com')
insert into Cliente values ('1734567890','Pedro Gomez','0983333333','pedro.gomez@email.com')
insert into Cliente values ('1745678901','Carla Vega','0984444444','carla.vega@email.com')
insert into Cliente values ('1756789012','Andres Luna','0985555555','andres.luna@email.com')
insert into Cliente values ('1767890123','Diana Castro','0986666666','diana.castro@email.com')

insert into Servicio values ('S01','Consulta general',35.00,'Consulta veterinaria de rutina','001')
insert into Servicio values ('S02','Vacunacion',25.00,'Aplicacion de vacunas','001')
insert into Servicio values ('S03','Bano',20.00,'Bano y limpieza de mascota','001')
insert into Servicio values ('S04','Peluqueria',30.00,'Corte y arreglo estetico','001')
insert into Servicio values ('S05','Traumatologia',60.00,'Evaluacion traumatologica especializada','002')
insert into Servicio values ('S06','Cirugia',250.00,'Procedimiento quirurgico veterinario','002')
insert into Servicio values ('S07','Radiografia',50.00,'Estudio radiografico','002')
insert into Servicio values ('S08','Hospitalizacion',80.00,'Hospitalizacion y monitoreo diario','002')

insert into Mascota values ('M01','Max','2021/03/15','Perro','Labrador','1712345678')
insert into Mascota values ('M02','Luna','2022/07/10','Gato','Siames','1723456789')
insert into Mascota values ('M03','Rocky','2020/11/05','Perro','Pastor aleman','1734567890')
insert into Mascota values ('M04','Mia','2023/01/20','Gato','Persa','1745678901')
insert into Mascota values ('M05','Toby','2019/08/12','Perro','Beagle','1756789012')
insert into Mascota values ('M06','Nala','2021/06/30','Gato','Mestizo','1767890123')
insert into Mascota values ('M07','Bruno','2022/02/14','Perro','Pug','1712345678')
insert into Mascota values ('M08','Kira','2020/09/25','Perro','Husky','1723456789')

insert into Historial values ('H01','M01','S01','E01','2026/05/02',35.00)
insert into Historial values ('H02','M02','S02','E01','2026/05/04',25.00)
insert into Historial values ('H03','M03','S03','E02','2026/05/06',20.00)
insert into Historial values ('H04','M04','S04','E02','2026/05/08',30.00)
insert into Historial values ('H05','M05','S01','E03','2026/05/10',35.00)
insert into Historial values ('H06','M01','S05','E05','2026/05/12',60.00)
insert into Historial values ('H07','M03','S06','E04','2026/05/15',250.00)
insert into Historial values ('H08','M06','S07','E05','2026/05/18',50.00)
insert into Historial values ('H09','M07','S08','E04','2026/05/20',80.00)
insert into Historial values ('H10','M08','S05','E05','2026/05/22',60.00)


/*--------------------------------------------*/
--- LISTO TODOS LOS REGISTROS
/*--------------------------------------------*/

select * from Sede
select * from Empleado
select * from Cliente
select * from Servicio
select * from Mascota
select * from Historial
