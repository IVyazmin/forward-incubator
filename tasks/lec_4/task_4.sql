CREATE PACKAGE commutator AS

CREATE SEQUENCE s_incb_commutator
  MINVALUE 1000
  MAXVALUE 9999999
  START WITH 1001
  INCREMENT BY 1
  CACHE 20;

CREATE OR REPLACE PROCEDURE getCOMMUTATOR(id_comm IN incb_commutator.id_commutator%TYPE,
                        curs OUT sys_refcursor)
IS

BEGIN
  
  OPEN curs FOR
    SELECT id_commutator, ip_address, id_commutator_type, 
    v_description, v_mac_address, v_community_read, 
    v_community_write, remote_id, b_need_convert_hex, remote_id_hex
    FROM incb_commutator
    WHERE b_deleted != 1
    AND id_commutator = id_comm;
    
   EXCEPTION WHEN NO_DATA_FOUND
     raise_application_error(-20028, 'коммутатора не существует');

END;

CREATE OR REPLACE PROCEDURE saveCOMMUTATOR(id_comm IN incb_commutator.id_commutator%TYPE DEFAULT NULL,
                                           ip_add IN incb_commutator.ip_address%TYPE DEFAULT NULL,
                                           id_type IN incb_commutator.id_commutator_type%TYPE DEFAULT NULL,
                                           v_descr IN incb_commutator.v_description%TYPE DEFAULT NULL,
                                           b_del IN incb_commutator.b_deleted%TYPE DEFAULT 0,
                                           v_mac IN incb_commutator.v_mac_address%TYPE DEFAULT NULL,
                                           v_comm_read IN incb_commutator.v_community_read%TYPE DEFAULT NULL,
                                           v_comm_write IN incb_commutator.v_community_write%TYPE DEFAULT NULL,
                                           rem_id IN incb_commutator.remote_id%TYPE DEFAULT NULL,
                                           b_need_c_hex IN incb_commutator.b_need_convert_hex%TYPE DEFAULT NULL,
                                           rem_hex IN incb_commutator.remote_id_hex%TYPE DEFAULT NULL)
                                           
IS
  n_count_comm NUMBER;
BEGIN
  IF b_del = 1
    THEN
      UPDATE incb_commutator
      SET b_deleted = 1
      WHERE id_commutator = id_comm;
    ELSE
      IF ((ip_add IS NULL) OR (v_mac IS NULL) OR (rem_id IS NULL) OR (v_comm_read IS NULL) OR (v_comm_write))
        THEN
          raise_application_error(-20031, 'Необходимые данные не указаны');
      END IF;
      SELECT COUNT(*)
      INTO n_count_comm
      FROM incb_commutator
      WHERE ip_address = ip_add
      OR v_mac_address = v_mac;
      IF n_count_comm != 0
        THEN
          raise_application_error(-20032, 'Коммутаторы с такими параметрами уже существуют');
      END IF
      IF ((b_need_c_hex = 1) AND (rem_hex IS NULL))
        THEN
          raise_application_error(-20033, 'Необходим идентификатор в формате HEX');
      END IF
      IF (NOT (ip_add LIKE '___.___.___.___'))
        THEN
          raise_application_error(-20034, 'Неверный формат IP адреса');
      END IF
      INSERT INTO incb_commutator(id_commutator, ip_address, id_commutator_type, v_description, 
                                  b_deleted, v_mac_address, v_community_read, v_community_write, 
                                  remote_id, b_need_convert_hex, remote_id_hex)
			VALUES(s_incb_commutator.nextval, ip_add, id_type, v_descr, b_del, v_mac, v_comm_read, 
             v_comm_write, rem_id, b_need_c_hex, rem_hex);
  END IF;
END;


CREATE OR REPLACE FUNCTION check_access_comm(ip_add IN incb_commutator.ip_address%TYPE, 
                                             v_community IN incb_commutator.v_community_read%TYPE,
                                             b_mode_write IN NUMBER) RETURN NUMBER
IS
 check_access NUMBER;
 v_check_access VARCHAR2;

BEGIN
  IF b_mode_write = 1
    THEN
      SELECT v_community_write
      INTO v_check_access
      FROM incb_commutator
      WHERE ip_address = ip_add;
    ELSE
      SELECT v_community_read
      INTO v_check_access
      FROM incb_commutator
      WHERE ip_address = ip_add;
  END IF;
  
  EXCEPTION WHEN NO_DATA_FOUND
     raise_application_error(-20028, 'коммутатора не существует');
      
  IF v_check_access = 'Есть'
    THEN
      check_access := 1;
    ELSE
      check_access := 0;
  END IF;
      
  RETURN check_access;
      
END;

CREATE OR REPLACE FUNCTION get_remote_id(id_comm IN incb_commutator.id_commutator%TYPE) RETURN VARCHAR2
IS
 get_rem incb_commutator%ROWTYPE;
 v_rem_id VARCHAR2;

BEGIN
  SELECT * IN get_rem FROM incb_commutator WHERE id_commutator = id_comm;
  EXCEPTION WHEN NO_DATA_FOUND
     raise_application_error(-20028, 'коммутатора не существует');
  
  IF get_rem.b_need_convert_hex = 1
    THEN
      IF get_rem.remote_id_hex IS NULL
        THEN
          raise_application_error(-20041, 'Неверный идентификатор');
        ELSE
          v_rem_id := get_rem.remote_id_hex;
      END IF;
    ELSE
      v_rem_id := TO_CHAR(get_rem.remote_id);
  END IF;
  
  RETURN v_rem_id;
      
END;

END pkgSalary;
