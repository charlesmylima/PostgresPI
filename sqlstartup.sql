
CREATE TABLE produtos (
    id_produto INT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    autor VARCHAR(100),
    preco DECIMAL(10, 2) NOT NULL
);

CREATE TABLE pedidos (
    id_pedido INT PRIMARY KEY,
    id_produto INT,
    cliente_nome VARCHAR(100),
    quantidade INT,
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

INSERT INTO produtos (id_produto, titulo, autor, preco)
VALUES
(1, 'Engenharia de Software Moderna', 'Marco Tulio Valente', 75.50),
(2, 'Front-end com Vue.js', 'Leonardo Vilarinho', 59.90),
(3, 'PHP & MySQL', 'Jon Duckett', 95.00);

INSERT INTO pedidos (id_pedido, id_produto, cliente_nome, quantidade)
VALUES
(101, 2, 'Ana Silva', 1),
(102, 1, 'Bruno Costa', 2),
(103, 3, 'Carla Dias', 1);