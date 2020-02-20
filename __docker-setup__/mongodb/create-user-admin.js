admin = db.getSiblingDB("admin")

/** User Admin */
admin.createUser(
  {
    user: "root",
    pwd: "rootpwd",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" }
    ]
  }
)

admin.auth("root", "rootpwd")

/** Replica Admin */
admin.createUser(
  {
    "user" : "replicaRoot",
    "pwd" : "replicarootpwd",
    roles: [
      { "role" : "clusterAdmin", "db" : "admin" }
    ]
  }
)