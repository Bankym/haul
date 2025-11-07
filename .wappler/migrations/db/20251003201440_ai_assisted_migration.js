// Database Migration

// Migration to create registration for users with three roles (driver=1, business=2, admin=3)
exports.up = async function (knex) {
    // Check if 'users' table exists
    const exists = await knex.schema.hasTable('users');
    if (!exists) {
        return knex.schema.createTable('users', function (table) {
            table.increments('id').primary();
            table.string('name', 255).notNullable();
            table.string('email', 255).notNullable().unique();
            table.string('password', 255).notNullable();
            table.integer('role').notNullable().defaultTo(1); // 1=driver, 2=business, 3=admin
            table.timestamps(true, true);
        });
    }
};

exports.down = async function (knex) {
    const exists = await knex.schema.hasTable('users');
    if (exists) {
        return knex.schema.dropTable('users');
    }
};
