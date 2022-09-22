CREATE TABLE asset (
    id int NOT NULL,
    user_id int NULL,
    serial_no varchar(255) NOT NULL,
    manufacturer varchar(1023) NULL,
    type varchar(255) NOT NULL
);

CREATE TABLE user (
    id int NOT NULL,
    name varchar(255) NOT NULL
);

INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (1, 1, 'SDFOIJSDFS', 'dell', 'screen');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (2, 1, 'FOP3ERSDSJ', 'dell', 'notebook');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (3, 1, 'L3LJSLISDJ', 'logitech', 'keyboard');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (4, 1, 'LSF89FSLSS', 'logitech', 'mouse');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (5, 2, 'LLKSFNSDOL', 'asus', 'notebook');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (6, 2, 'LI45HJSLFS', 'phillips', 'screen');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (7, 2, 'LJWFODSIF4', 'cherry', 'keyboard');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (8, 2, '89HVIORW42', 'microsoft', 'mouse');
INSERT INTO asset (id, user_id, serial_no, manufacturer, type) VALUES (9, NULL, 'SDFOI8U9SF', 'phillips', 'screen');

INSERT INTO user (id, name) VALUES (1, 'Donald');
INSERT INTO user (id, name) VALUES (2, 'Uncle Scrooge');
