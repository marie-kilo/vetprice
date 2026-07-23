 ~/.pyenv/pyenv-win/versions/3.14.2/python.exe -m venv env
 pyenv install 3.14.5    
  pyenv local 3.14.5
  python -m venv env      
  env\Scripts\activate   
  python -m pip install --upgrade pip      
  pip install -r requirements.txt   



  psql -U postgres -c "CREATE DATABASE vetprice;"      


  psql -U postgres -d vetprice -f schema.sql   


