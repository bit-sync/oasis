from flask import Flask, send_from_directory, abort, render_template_string, url_for
import os

app = Flask(__name__)

# Specify the directory to serve files from
CDN_DIRECTORY = 'repo'  # Change this to your desired directory

def safe_join(directory, path):
    # Join the directory and the requested path
    final_path = os.path.join(directory, path)
    # Ensure the final path is within the directory
    if os.path.commonprefix([os.path.realpath(final_path), os.path.realpath(directory)]) == os.path.realpath(directory):
        return final_path
    return None

@app.route('/', defaults={'filename': ''})
@app.route('/<path:filename>')
def serve_file(filename):
    # Safely join the directory and filename
    file_path = safe_join(CDN_DIRECTORY, filename)
    if file_path is None:
        abort(404)  # File not found

    if os.path.isdir(file_path):
        return list_directory(file_path, filename)
    elif os.path.isfile(file_path):
        return send_from_directory(CDN_DIRECTORY, filename)
    else:
        abort(404)

def list_directory(directory, url_path):
    try:
        files = os.listdir(directory)
        files_list = '<br>'.join([f'<a href="{url_for("serve_file", filename=os.path.join(url_path, file))}">{file}</a>' for file in files])
        
        # Add a link to the parent directory if not at the root
        if url_path:
            parent_dir = os.path.dirname(url_path)
            parent_link = f'<a href="{url_for("serve_file", filename=parent_dir)}">.. (parent directory)</a><br>'
            files_list = parent_link + files_list

        return render_template_string('<h1>{{ directory }}</h1><p>{{ files_list | safe }}</p>', directory=directory, files_list=files_list)
    except Exception as e:
        abort(404)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)