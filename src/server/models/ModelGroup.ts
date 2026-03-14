import { DataTypes } from 'sequelize'
import { sequelize } from '../config/database.js'

const ModelGroup = sequelize.define(
  'ModelGroup',
  {
    id: {
      type: DataTypes.INTEGER,
      field: 'mg_id',
      primaryKey: true,
      autoIncrement: true,
    },
    name: { type: DataTypes.STRING(40), field: 'mg_name' },
    path: { type: DataTypes.STRING(30), field: 'mg_path' },
  },
  {
    tableName: 'fgs_modelgroups',
    timestamps: false,
  }
)

export default ModelGroup
