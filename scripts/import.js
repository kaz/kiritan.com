"use strict";

const {orderedItems} = require("./outbox.json");

console.log(`
	DELETE FROM conversations;
	DELETE FROM statuses;
	SELECT setval('conversations_id_seq', 1, false);
	SELECT setval('statuses_id_seq', 1, false);
`);

for(const {object: {id, published, content}} of orderedItems){
	const [, numID] = id.match(/^.+\/(\d+)$/);
	const [, message] = content.match(/^<p>(.+)<\/p>$/);
	console.log(`
		INSERT INTO conversations (id, created_at, updated_at) VALUES(
			nextval('conversations_id_seq'),
			'${published}',
			'${published}'
		);
		INSERT INTO statuses (id, uri, text, created_at, updated_at, visibility, language, local, conversation_id, account_id) VALUES (
			${numID},
			'https://kiritan.com/users/tohoku/statuses/${numID}',
			'${message}',
			'${published}',
			'${published}',
			2,
			'ja',
			true,
			nextval('statuses_id_seq'),
			1
		);
	`);
}

console.log(`
	UPDATE account_stats SET statuses_count = currval('statuses_id_seq') WHERE id = 1;
`);
