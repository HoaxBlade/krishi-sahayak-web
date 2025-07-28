from utils.dataloader import get_generators
from utils.train import train_model

if __name__ == "__main__":
    train_gen, val_gen, num_classes = get_generators("Data", "labels.txt")
    model, history = train_model(train_gen, val_gen, num_classes)