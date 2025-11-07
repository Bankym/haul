
exports.up = function(knex) {
  return knex.schema
    .table('users', async function (table) {
      table.integer('role').comment('driver=1, business=2, admin=3').alter();
    })

};

exports.down = function(knex) {
  return knex.schema
    .table('users', async function (table) {
      table.integer('role').comment('').alter();
    })
};
