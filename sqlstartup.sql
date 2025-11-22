CREATE TABLE produtos (
    id_produto SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('SERVICO', 'MATERIAL_CONSUMO', 'MATERIAL_DURAVEL')),
    preco_venda DECIMAL(10, 2) NOT NULL,
    estoque_atual INT DEFAULT 0
);

CREATE TABLE pessoas (
    id_pessoa SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(20),
    tipo_pessoa VARCHAR(2) NOT NULL CHECK (tipo_pessoa IN ('PF', 'PJ')),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pessoas_fisicas (
    id_pessoa INT PRIMARY KEY REFERENCES pessoas(id_pessoa) ON DELETE CASCADE,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    rg VARCHAR(20),
    data_nascimento DATE
);

CREATE TABLE pessoas_juridicas (
    id_pessoa INT PRIMARY KEY REFERENCES pessoas(id_pessoa) ON DELETE CASCADE,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    razao_social VARCHAR(150) NOT NULL,
    inscricao_estadual VARCHAR(20)
);

CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    id_pessoa INT NOT NULL REFERENCES pessoas(id_pessoa),
    limite_credito DECIMAL(10, 2) DEFAULT 0.00,
    vip BOOLEAN DEFAULT FALSE,
    UNIQUE(id_pessoa)
);

CREATE TABLE fornecedores (
    id_fornecedor SERIAL PRIMARY KEY,
    id_pessoa INT NOT NULL REFERENCES pessoas(id_pessoa),
    contato_principal VARCHAR(100),
    prazo_pagamento_padrao INT DEFAULT 30,
    UNIQUE(id_pessoa)
);

-- 2. Tabela Movimentação

CREATE TABLE pedidos_venda (
    id_pedido_venda SERIAL PRIMARY KEY,
    id_cliente INT REFERENCES clientes(id_cliente),
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ABERTO' CHECK (status IN ('ABERTO', 'FECHADO', 'CANCELADO')),
    total_pedido DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE itens_venda (
    id_item_venda SERIAL PRIMARY KEY,
    id_pedido_venda INT REFERENCES pedidos_venda(id_pedido_venda) ON DELETE CASCADE,
    id_produto INT REFERENCES produtos(id_produto),
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10, 2) NOT NULL
);

CREATE TABLE pedidos_compra (
    id_pedido_compra SERIAL PRIMARY KEY,
    id_fornecedor INT REFERENCES fornecedores(id_fornecedor),
    data_emissao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    prazo_entrega DATE NOT NULL, -- Requisito: Prazo de compra
    status VARCHAR(20) DEFAULT 'SOLICITADO' CHECK (status IN ('SOLICITADO', 'RECEBIDO', 'CANCELADO'))
);

CREATE TABLE itens_compra (
    id_item_compra SERIAL PRIMARY KEY,
    id_pedido_compra INT REFERENCES pedidos_compra(id_pedido_compra) ON DELETE CASCADE,
    id_produto INT REFERENCES produtos(id_produto),
    quantidade INT NOT NULL CHECK (quantidade > 0),
    custo_unitario DECIMAL(10, 2) NOT NULL
);

-- 3. Logs e Notificações

CREATE TABLE notificacoes (
    id_notificacao SERIAL PRIMARY KEY,
    mensagem TEXT NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lida BOOLEAN DEFAULT FALSE
);

CREATE TABLE logs_sistema (
    id_log SERIAL PRIMARY KEY,
    tabela_afetada VARCHAR(50) NOT NULL,
    operacao VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    usuario_db VARCHAR(50) DEFAULT CURRENT_USER,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dados_antigos JSONB, -- Armazena o estado anterior (apenas PostgreSQL)
    dados_novos JSONB    -- Armazena o estado novo
);

-- 4. Triggers e Funções
CREATE OR REPLACE FUNCTION notificar_venda_realizada()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notificacoes (mensagem)
    VALUES (CONCAT('Novo pedido de venda #', NEW.id_pedido_venda, ' realizado para o cliente ID: ', NEW.id_cliente));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notificar_venda
AFTER INSERT ON pedidos_venda
FOR EACH ROW
EXECUTE FUNCTION notificar_venda_realizada();

CREATE OR REPLACE FUNCTION registrar_log_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO logs_sistema (tabela_afetada, operacao, dados_novos)
        VALUES (TG_TABLE_NAME, 'INSERT', row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO logs_sistema (tabela_afetada, operacao, dados_antigos, dados_novos)
        VALUES (TG_TABLE_NAME, 'UPDATE', row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO logs_sistema (tabela_afetada, operacao, dados_antigos)
        VALUES (TG_TABLE_NAME, 'DELETE', row_to_json(OLD)::jsonb);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_produtos AFTER INSERT OR UPDATE OR DELETE ON produtos FOR EACH ROW EXECUTE FUNCTION registrar_log_auditoria();
CREATE TRIGGER trg_log_clientes AFTER INSERT OR UPDATE OR DELETE ON clientes FOR EACH ROW EXECUTE FUNCTION registrar_log_auditoria();
CREATE TRIGGER trg_log_pedidos_venda AFTER INSERT OR UPDATE OR DELETE ON pedidos_venda FOR EACH ROW EXECUTE FUNCTION registrar_log_auditoria();
CREATE TRIGGER trg_log_pedidos_compra AFTER INSERT OR UPDATE OR DELETE ON pedidos_compra FOR EACH ROW EXECUTE FUNCTION registrar_log_auditoria();

-- 5. Dados Iniciais
id_cliente SERIAL PRIMARY KEY,
id_pessoa INT NOT NULL REFERENCES pessoas(id_pessoa),
limite_credito DECIMAL(10, 2) DEFAULT 0.00,
vip BOOLEAN DEFAULT FALSE,
UNIQUE(id_pessoa);

INSERT INTO produtos (nome, tipo, preco_venda, estoque_atual) VALUES 
('Formatação de PC', 'SERVICO', 150.00, 0),
('Resma de Papel A4', 'MATERIAL_CONSUMO', 25.00, 100),
('Monitor 24pol', 'MATERIAL_DURAVEL', 1200.00, 10);

INSERT INTO pedidos_venda (id_cliente, total_pedido) VALUES (1, 1225.00);

INSERT INTO itens_venda (id_pedido_venda, id_produto, quantidade, preco_unitario) VALUES 
(1, 2, 1, 25.00),
(1, 3, 1, 1200.00);

INSERT INTO pedidos_compra (id_fornecedor, prazo_entrega) VALUES (1, '2025-12-01');