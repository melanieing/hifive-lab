import boto3
import hcl2
import os
from datetime import datetime

def get_tf_config():
    """스크립트 위치 기준 상위 폴더의 variables.tf에서 변수 로드"""
    current_dir = os.path.dirname(os.path.abspath(__file__))
    tf_path = os.path.join(current_dir, '..', 'variables.tf')
    
    try:
        with open(tf_path, 'r', encoding='utf-8') as f:
            dict_vars = hcl2.load(f)
        
        config = {}
        for var in dict_vars.get('variable', []):
            for name, details in var.items():
                config[name] = details.get('default')
        print(f"✅ variables.tf 로드 완료 (Project: {config.get('project_name')})")
        return config
    except FileNotFoundError:
        print(f"⚠️ {tf_path}를 찾을 수 없어 기본값을 사용합니다.")
        return {"region": "ap-northeast-2", "project_name": "hifive-lab"}

def run_automation():
    # 1. 환경 설정 로드
    config = get_tf_config()
    region = config.get('region')
    project = config.get('project_name')
    
    rds = boto3.client('rds', region_name=region)
    s3 = boto3.client('s3', region_name=region)
    
    cluster_id = f"{project}-aurora"
    
    try:
        # 2. RDS 스냅샷 조회 (SnapshotType 생략하여 전체 조회)
        snapshots = rds.describe_db_cluster_snapshots(
            DBClusterIdentifier=cluster_id
        )
        
        if snapshots['DBClusterSnapshots']:
            # 가장 최근 생성된 스냅샷 정렬 추출
            latest = sorted(snapshots['DBClusterSnapshots'], 
                            key=lambda x: x['SnapshotCreateTime'], 
                            reverse=True)[0]
            
            status_msg = (f"[{datetime.now()}] Project: {project}\n"
                            f"Latest Snapshot: {latest['DBClusterSnapshotIdentifier']}\n"
                            f"Status: {latest['Status']}\n"
                            f"Created at: {latest['SnapshotCreateTime']}")
        else:
            status_msg = f"[{datetime.now()}] {project} 관련 스냅샷을 찾을 수 없습니다."

        print(f"🔍 분석 결과:\n{status_msg}")

        # 3. S3에 로그 저장 (Step 1에서 만든 버킷 활용)
        # 버킷 이름은 실제 문주님의 S3 버킷 이름으로 수정하세요.
        bucket_name = "hifive-lab-tfstate-4v2r6p06" 
        log_key = f"backup-reports/status_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        
        s3.put_object(
            Bucket=bucket_name,
            Key=log_key,
            Body=status_msg
        )
        print(f"📤 S3 업로드 성공: s3://{bucket_name}/{log_key}")

    except Exception as e:
        print(f"❌ 작업 중 에러 발생: {e}")

if __name__ == "__main__":
    run_automation()