drop table clientes cascade constraints;
drop table productos cascade constraints;
drop table pedidos cascade constraints;
drop table repartidor cascade constraints;
drop table zonas cascade constraints;
drop table carrito cascade constraints;
drop table contiene cascade constraints;
drop table tiene cascade constraints;
drop table cheques cascade constraints;
drop sequence NumPedido;
drop sequence NumCheque;

create sequence NumPedido  MINVALUE 1 START WITH 1
    INCREMENT BY 1 NOCACHE;

create sequence NumCheque  MINVALUE 1 START WITH 1
    INCREMENT BY 1 NOCACHE;

create table clientes (
  email varchar2(20) NOT NULL,
  nombre varchar2(15) NOT NULL,
  apellidos varchar2(20) NOT NULL,
  num_tarjeta number(16)  DEFAULT 0,
  tlfno number(9)  DEFAULT 0,
  num_socio varchar2(7) NOT NULL,
  password varchar2(8) NOT NULL,
  via varchar2(8) NOT NULL,
  nom_via varchar2(15) NOT NULL,
  num_piso number(3)  DEFAULT 0,
  letra char(1) NOT NULL,
  codpostal number(5),
  primary key(email)
);


create table productos(
  codbarras number(10)  DEFAULT 0,
  precio number(4) DEFAULT 0,
  descripcion varchar2(10),
  tipo varchar2(9) NOT NULL,
  descuento varchar2(3) default NULL,
  primary key(codbarras)
);



create table pedidos(
  email varchar2(20) NOT NULL,
  identificador number(3) DEFAULT 0,
  fecha date NOT NULL,
  importe number(6,2) DEFAULT 0,
  idRepartidor number(5) default null,
  CONSTRAINT pe_pk primary key (identificador),
  constraint pe_fk foreign key (email) references clientes on delete cascade
);

create table carrito(
  email  varchar2(20) NOT NULL,
  codbarras number(10) DEFAULT 0,
  peso number(3) DEFAULT 0 CHECK (peso >=0),
  unidades number(3) DEFAULT 0 CHECK (unidades >=0),
  constraint ca_pk primary key (email,codbarras),
  constraint ca1_fk foreign key (codbarras) references productos on delete cascade,
  constraint ca2_fk foreign key (email) references clientes on delete cascade
);

create table contiene(
    codbarras number(10) DEFAULT 0,
    identificador number(3) DEFAULT 0,
    peso number(3) DEFAULT 0 CHECK (peso >=0),
    unidades number(3) DEFAULT 0 CHECK (unidades >=0),
    constraint co_pk primary key (codbarras,identificador),
    constraint co_fk foreign key (codbarras) references productos on delete cascade,
    constraint co1_fk foreign key (identificador) references pedidos on delete cascade
);

create table cheques(
  email varchar2(20) NOT NULL,
  num_cheque number(5) DEFAULT 0,
  imp_descuento number(4) DEFAULT 0 CHECK (imp_descuento >=0),
  imp_min number(3) DEFAULT 0 CHECK (imp_min >=0),
  fechacad date NOT NULL,
  identificador number(3) DEFAULT null,
  constraint ch_pk primary key (num_cheque,email),
  constraint ch_fk foreign key (identificador) references pedidos on delete cascade,
  constraint ch1_fk foreign key (email) references clientes on delete cascade
);


create table repartidor(
    num_empleado number(4) NOT NULL,
    constraint re_pk primary key(num_empleado)
);

create table zonas(
    cod_postal number(5) primary key
);


create table tiene(
  codpostal number(5),
  num_empleado number(4),
  constraint t_pk primary key (codpostal,num_empleado),
  constraint t_fk foreign key (num_empleado) references repartidor on delete cascade,
  constraint t1_fk foreign key (codpostal) references zonas on delete cascade
);

insert into clientes values('alvago07@ucm.es','Alvaro','Gonzalez Sanchez','99087345665','925823454','0000001','uhfrru','Calle','Alvarado','5','D','28001');
insert into clientes values('pedro7@ucm.es','Pedro','Perez Sanchez','45600049999','910800454','0000002','ertrru','Calle','Perez','6','I','28010');
insert into clientes values('Gonzalo5g@ucm.es','Gonzalo','Alvarez Sanchez','2345789090000000','925829876','0000003','uhfghu','Avenida','PIOXII','3','D','28005');
insert into clientes values('alex@hotmail.com','Alejandro','Gonzalez Sanchez','2345789090000543','912345789','0000004','igjitgi','Calle','Perez','4','I','28001');
insert into clientes values('irene@gmail.com','Irene','Gonzalez Valero','2345789090444483','932345709','0000005','PgKitHi','Avenida','FranciscoXII','4','I','28010');

insert into productos values('1232134560','5','tomate','frescos','10'); 
insert into productos values('2345676543','1,75','lechugas','frescos','20');
insert into productos values('1456764346','3,00','merluza','envasados','3x2');
insert into productos values('0232134560','0,75','patatas','frescos','10');
insert into productos values('4565432348','7,50','ternera','frescos','2x1');
insert into productos values('9835432348','1,50','berenjenas','envasados','3x2');

insert into carrito values('alvago07@ucm.es','1232134560','15',null);
insert into carrito values('alvago07@ucm.es','2345676543','15',null);
insert into carrito values('alvago07@ucm.es','9835432348',null,'23');
insert into carrito values('alvago07@ucm.es','0232134560','22',null);
insert into carrito values('irene@gmail.com','1232134560','23',null);
insert into carrito values('irene@gmail.com','0232134560','22',null);
insert into carrito values('irene@gmail.com','9835432348',null,'30');

insert into repartidor values('0001');
insert into repartidor values('0002');
insert into repartidor values('0003');

insert into zonas values('28001');
insert into zonas values('28005');
insert into zonas values('28010');

insert into tiene values('28001','0001');
insert into tiene values('28001','0002');
insert into tiene values('28005','0002');
insert into tiene values('28010','0003');


insert into cheques values('alvago07@ucm.es',NumCheque.NEXTVAL,'5','10','31/01/2015',null);
insert into cheques values('irene@gmail.com',NumCheque.NEXTVAL,'1','5','31/01/2015',null);

/*3. Trigger que registre un cheque descuento a un cliente cuando este confirme un pedido y se trate de un socio.
El importe corresponderá al 3% del total del pedido y será aplicable a pedidos que superen un importe igual al 50% del importe del pedido actual.
El cheque caducara en 3 meses desde la fecha actual.*/
/
create or replace 
TRIGGER  registra_cheque_trigger
AFTER INSERT ON pedidos	
DECLARE
v_importe number(6,2);
v_email varchar2(20) ;
v_fecha date ;

BEGIN
  select email,importe,fecha into v_email,v_importe,v_fecha
  from PEDIDOS
  where IDENTIFICADOR >= all (select IDENTIFICADOR from pedidos);
	--instrucciones a hacer si el disparador salto por insertar algun pedido
  insert into cheques values(v_email,NumCheque.NEXTVAL,(v_importe*0.03),(v_importe*0.50),(sysdate + 90),NULL);
	
END;

/*1. Procedimiento que permita confirmar un pedido. Dicho procedimiento recibirá como parámetro el email de un cliente.
El procedimiento deberá generar un nuevo pedido con el contenido del carrito, así como vaciar este último.
Además deberá calcular el importe total del pedido teniendo en cuenta los precios y los descuentos vigentes. 
Se comprobará si hay cheques de descuento aplicables. Solo se aplicara uno de ellos, el primero disponible en número de orden.
El importe se descontara del precio total del pedido. Deberá quedar reflejado en la base de datos el pedido al que fue aplicado.
El procedimiento emitirá un informe con el detalle del pedido: código de producto, descripción, unidades/peso,
importe y descuento si procede, así como el importe total del mismo.
En caso de que el carrito este vacío y se intente confirmar un pedido se mostrara un mensaje que informe de ello.*/
/
create or replace procedure confirmapedido
(v_email varchar2)
is
  cursor cursor1 is
      select distinct PRODUCTOS.CODBARRAS,PRODUCTOS.descripcion,productos.precio,productos.descuento,productos.tipo,carrito.unidades,carrito.peso,clientes.email
      from clientes,carrito,PRODUCTOS
      where v_email = clientes.email and clientes.email = carrito.email and productos.codbarras = carrito.codbarras;
      
      rPedido cursor1%ROWTYPE;
      
    cursor cursor2 is
      select distinct email,imp_descuento,imp_min,num_cheque 
          from cheques
          where v_email = cheques.email and sysdate < cheques.FECHACAD;
          
      rCheque cursor2%ROWTYPE;
      
   v_importe number(6,2);
   v_aux varchar2(20);
   v_cantidad_descuento number(4,2);
   v_unidades_aux number(3);
   v_cont number(1);
   
  TB constant varchar2(1):=CHR(9);
  
begin

    open cursor1;
    v_importe := 0;
    
    dbms_output.put_line(rpad('CODIGO PRODUCTO',30,' ')||TB||rpad('DESCRIPCION',20,' ')
    ||TB||rpad('UNIDADES/PESO',20,' ')||TB||rpad('IMPORTE',20,' ')||TB||rpad('DESCUENTO',20,' '));
    dbms_output.put_line(rpad('-',136,'-'));
    
    
    
    loop
      
      fetch cursor1 into rPedido;
      exit when cursor1%NOTFOUND; 
      
         v_aux := rPedido.descuento; 
        
        if(rPedido.tipo = 'frescos') then
        
            if(rPedido.descuento is not null) then
                v_cantidad_descuento := TO_NUMBER(v_aux);
                v_cantidad_descuento := rPedido.precio * (v_cantidad_descuento/100);
                v_importe := (rPedido.peso*(rPedido.precio-v_cantidad_descuento)) + v_importe;
            else
                v_importe := (rPedido.peso*rPedido.precio) + v_importe;
            end if;  
        else
        
            if(rPedido.descuento is not null) then
                v_aux := SUBSTR(rPedido.descuento,1,1);
                v_cantidad_descuento := TO_NUMBER(v_aux);
                v_unidades_aux := (rPedido.unidades-((rPedido.unidades-MOD(rPedido.unidades,v_cantidad_descuento))/v_cantidad_descuento));
                v_importe := (v_unidades_aux*rPedido.precio) + v_importe;
            else
                v_importe := (rPedido.unidades*rPedido.precio) + v_importe;
            end if;
            
      end if;        
        
           if(rPedido.tipo = 'frescos') then
                  dbms_output.put_line(rpad(rPedido.codbarras,30,' ')||TB||rpad(rPedido.descripcion,20,' ')||TB||rpad(rPedido.peso,20,' ')
                  ||TB||rpad(rPedido.peso*rPedido.precio,20,' ')||TB||rpad(rPedido.descuento,20,' '));
            else  dbms_output.put_line(rpad(rPedido.codbarras,30,' ')||TB||rpad(rPedido.descripcion,20,' ')||TB||rpad(rPedido.unidades,20,' ')
                  ||TB||rpad(rPedido.unidades*rPedido.precio,20,' ')||TB||rpad(rPedido.descuento,20,' '));
            end if;
            
    end loop;
      close cursor1;
      
      select nvl(count(*),0) into v_cont
      from cheques
      where v_email = cheques.email and sysdate < cheques.fechacad;
      
       
    if(v_cont > 0) then
          open cursor2;
          fetch cursor2 into rCheque;
          close cursor2;
          
        if(v_importe >= rCheque.imp_min) then
        
          v_importe := (v_importe - rCheque.imp_descuento);
          
        end if;   
        
    end if;
      dbms_output.put_line(' ');
      dbms_output.put_line('El importe total del pedido es ' || v_importe);
      
      insert into pedidos values(v_email,NumPedido.NEXTVAL,sysdate,v_importe,null);
      
      update cheques
      set identificador = NumPedido.CURRVAL
      where cheques.email = v_email and cheques.num_cheque = rCheque.num_cheque;
      
      delete from carrito
      where email = v_email;
    
      
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No hay carrito para este email: ' || v_email);
        
end;
/
begin
  confirmapedido('irene@gmail.com');
  confirmapedido('alvago07@ucm.es');
end;
/
SET SERVEROUTPUT ON
/*2. Procedimiento que genere un informe con los pedidos pendientes de reparto (aquellos que no tienen asociado un repartidor)
y los repartidores disponibles para su asignación. Un repartidor puede ser asignado a un pedido si el código postal de la dirección
de entrega del pedido se encuentra entre los asociados al repartidor.*/
create or replace procedure pedidospendientes
is
  cursor curs is
      select  tiene.num_empleado,clientes.codpostal,pedidos.identificador
      from pedidos,tiene,clientes
      where clientes.email = pedidos.email and clientes.codpostal = tiene.codpostal and pedidos.idRepartidor is null
      order by pedidos.identificador;

      v_identificador number(3);
      v_repartidor number(4);
      v_codpostal number(5);
      
      
      TB constant varchar2(1):=CHR(9);
     
begin 
  
    open curs;

     dbms_output.put_line(rpad('ID pedido',20,' ')||TB||rpad('ID Repartidor disponible',30,' '));
     dbms_output.put_line(rpad('-',136,'-'));

    loop
      fetch curs into v_repartidor,v_codpostal,v_identificador;
      exit when curs%NOTFOUND;

      dbms_output.put_line(rpad(v_identificador,28,' ')||TB||rpad(v_repartidor,30,' '));
      
    end loop;
    
      close curs;
end;
/
begin
pedidospendientes();
end;
/

SET SERVEROUTPUT ON




