const AWS = require('aws-sdk');
const s3 = new AWS.S3()
const dynamoDb = new AWS.DynamoDB.DocumentClient();
const crypto = require("crypto");

module.exports.readS3file = async (event) => {
    const id = crypto.randomBytes(16).toString("hex");
    const Key = event.Records[0].s3.object.key

    const data = await s3.getObject({
        Bucket: event.Records[0].s3.bucket.name,
        Key
    }).promise();

    console.log("Data", data)
    let objectData = data.Body.toString('utf-8');
    console.log(objectData)

    const TableName = process.env.TABLE_NAME
    const params = {
        TableName,
        Item: {
            'id': id,
            'fileName': Key,
            'fileContent': objectData.substring(0, 20),
            'dataTime': new Date().toISOString()
        }
    }
    await dynamoDb.put(params).promise();
}