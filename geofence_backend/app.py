import os
import json
import psycopg2
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from flask_cors import CORS
from shapely.geometry import Point, Polygon

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app) # Enable Cross-Origin Resource Sharing for your Flutter app

# --- Database Connection ---
# Establishes a connection to the PostgreSQL database using the URL from .env
def get_db_connection():
    """Connects to the database."""
    try:
        conn = psycopg2.connect(os.environ['DATABASE_URL'])
        return conn
    except psycopg2.OperationalError as e:
        print(f"Could not connect to database: {e}")
        raise

# --- API Endpoints ---

@app.route('/geofences', methods=['POST'])
def add_geofence():
    """
    API endpoint for an admin to add a new geofence.
    Expects a JSON body with 'name' and 'area' (a list of coordinate pairs).
    """
    data = request.get_json()
    if not data or 'name' not in data or 'area' not in data:
        return jsonify({'error': 'Missing name or area data'}), 400

    name = data['name']
    # The 'area' should be a list of lists, e.g., [[lat, lon], [lat, lon], ...]
    area_coords = data['area']

    if len(area_coords) < 3:
        return jsonify({'error': 'A polygon must have at least 3 points'}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        # Storing coordinates as a JSONB field in the 'geofences' table
        cur.execute("INSERT INTO geofences (name, area) VALUES (%s, %s)",
                    (name, json.dumps(area_coords)))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'message': 'Geofence added successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/geofences', methods=['GET'])
def get_geofences():
    """
    API endpoint for the client app to fetch all existing geofences to display on the map.
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, area FROM geofences")
        geofences_data = cur.fetchall()
        cur.close()
        conn.close()

        # Format the database rows into a list of JSON objects
        result = [
            {'id': row[0], 'name': row[1], 'area': row[2]}
            for row in geofences_data
        ]
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/check_location', methods=['POST'])
def check_location():
    """
    API endpoint to check if a user's location is inside any defined geofence.
    Expects 'latitude' and 'longitude' in the JSON body.
    """
    data = request.get_json()
    if not data or 'latitude' not in data or 'longitude' not in data:
        return jsonify({'error': 'Missing location data (latitude/longitude)'}), 400

    user_point = Point(data['latitude'], data['longitude'])
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, area FROM geofences")
        geofences_data = cur.fetchall()
        cur.close()
        conn.close()
        
        zones_inside = []
        for fence_data in geofences_data:
            polygon_coords = fence_data[2] # The JSONB 'area' field from the DB
            polygon = Polygon(polygon_coords)

            if polygon.contains(user_point):
                zones_inside.append({'id': fence_data[0], 'name': fence_data[1]})

        if zones_inside:
            return jsonify({
                'is_inside': True,
                'zones': zones_inside
            }), 200
        else:
            return jsonify({'is_inside': False, 'zones': []}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/incidents', methods=['GET'])
def get_incidents():
    incidents = [
        {"id": "1", "title": "Theft at City Park", "description": "Bag stolen", "severity": "High", "reportedAt": "10 mins ago"},
        {"id": "2", "title": "Suspicious Activity", "description": "Loitering", "severity": "Medium", "reportedAt": "30 mins ago"},
        {"id": "3", "title": "Lost Tourist", "description": "Needs help", "severity": "Low", "reportedAt": "1 hour ago"}
    ]
    return jsonify(incidents)

# --- Main execution block ---
if __name__ == '__main__':
    # Runs the Flask app on localhost, port 5000, accessible from the network.
    # debug=True enables auto-reload on code changes.
    app.run(debug=True, host='0.0.0.0', port=5000)