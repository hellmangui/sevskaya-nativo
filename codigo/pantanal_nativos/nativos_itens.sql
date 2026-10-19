-- pantanal_nativos (16/10/2026): item que acende a fogueira ritual nos pontos sagrados.
-- Mesmo formato da lata_tinta_mafia (usável, não é gasto ao acender). Rodar uma vez no banco.
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `useExpired`, `groupId`, `rarityId`, `metadata`, `desc`, `degradation`, `weight`, `durability`, `instructions`) VALUES
	('fogueira_ritual', 'Fogueira Ritual', 10, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Lenha seca, ervas e pederneira dos anciões. Acende a fogueira que marca a terra como da tribo.', 0, 0.50, NULL, NULL);

-- As tabelas do conselho (nativos_gangs, nativos_members, nativos_locations, ...) e a do Wampum
-- (nativos_wampum) o próprio recurso cria ao subir. As da missão de território estão em
-- pantanal_nativos_missoes/territory_mission.sql.

-- Falcoaria (16/10/2026): gaiola de captura, viveiro da tribo e uma ave-item por espécie.
-- Cada ave leva os dados dela no item (metadata: aveId, sexo, grau), então cada uma ocupa a própria pilha.
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `useExpired`, `groupId`, `rarityId`, `metadata`, `desc`, `degradation`, `weight`, `durability`, `instructions`) VALUES
	('gaiola_falcoeiro', 'Gaiola de Falcoeiro', 5, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Gaiola de vime dos falcoeiros Kohani. Use perto de um ninho para prender a ave.', 0, 1.00, NULL, NULL),
	('viveiro_tribo', 'Viveiro da Tribo', 1, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Gaiolas, poleiros e ninho de palha. O chefe monta perto da fogueira do conselho.', 0, 5.00, NULL, NULL),
	('ave_aguia', 'Águia', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Águia criada pelos nativos. Use para chamá-la.', 0, 2.00, NULL, NULL),
	('ave_gaviao', 'Gavião', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Gavião criado pelos nativos. Use para chamá-lo.', 0, 1.50, NULL, NULL),
	('ave_garca', 'Garça', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Garça criada pelos nativos. Use para chamá-la.', 0, 1.50, NULL, NULL),
	('ave_pelicano', 'Pelicano', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Pelicano criado pelos nativos. Use para chamá-lo.', 0, 2.00, NULL, NULL),
	('ave_corvo', 'Corvo', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Corvo criado pelos nativos. Use para chamá-lo.', 0, 1.00, NULL, NULL),
	('ave_urubu', 'Urubu', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Urubu criado pelos nativos. Use para chamá-lo.', 0, 1.50, NULL, NULL),
	('ave_arara', 'Arara-vermelha', 3, 1, 'item_standard', 1, 0, 1, 1, '{}', 'Arara criada pelos nativos. Use para chamá-la.', 0, 1.00, NULL, NULL);
