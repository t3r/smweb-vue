import { DataTypes } from 'sequelize'
import { sequelize } from '../config/database.js'

const Author = sequelize.define(
  'Author',
  {
    id: {
      type: DataTypes.INTEGER,
      field: 'au_id',
      primaryKey: true,
      autoIncrement: true,
    },
    name: { type: DataTypes.STRING(40), field: 'au_name' },
    email: { type: DataTypes.STRING(40), field: 'au_email' },
    notes: { type: DataTypes.TEXT, field: 'au_notes' },
    modeldir: { type: DataTypes.CHAR(3), field: 'au_modeldir' },
  },
  {
    tableName: 'fgs_authors',
    timestamps: false,
  }
)

export default Author
