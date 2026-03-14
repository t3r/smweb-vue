import { DataTypes } from 'sequelize'
import { sequelize } from '../config/database.js'
import Author from './Author.js'
import ModelGroup from './ModelGroup.js'

const Model = sequelize.define(
  'Model',
  {
    id: {
      type: DataTypes.INTEGER,
      field: 'mo_id',
      primaryKey: true,
      autoIncrement: true,
    },
    path: { type: DataTypes.STRING(100), field: 'mo_path', allowNull: false },
    modified: { type: DataTypes.DATE, field: 'mo_modified' },
    authorId: { type: DataTypes.INTEGER, field: 'mo_author' },
    name: { type: DataTypes.STRING(100), field: 'mo_name' },
    notes: { type: DataTypes.TEXT, field: 'mo_notes' },
    thumbfile: { type: DataTypes.TEXT, field: 'mo_thumbfile' },
    modelfile: { type: DataTypes.TEXT, field: 'mo_modelfile', allowNull: false },
    shared: { type: DataTypes.INTEGER, field: 'mo_shared' },
    modifiedBy: { type: DataTypes.INTEGER, field: 'mo_modified_by' },
    deleted: { type: DataTypes.DATE, field: 'mo_deleted', allowNull: true },
  },
  {
    tableName: 'fgs_models',
    timestamps: false,
  }
)

Model.belongsTo(Author, { foreignKey: 'authorId' })
Model.belongsTo(ModelGroup, { foreignKey: 'shared' })

export default Model
